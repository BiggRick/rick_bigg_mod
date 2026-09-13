from __future__ import annotations

import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass
class BmpImage:
    path: Path
    width: int
    height: int
    palette: bytes
    pixel_data: bytes
    colors_used: int
    transparent_index: int = 0


def _read_u16(data: bytes, offset: int) -> int:
    return struct.unpack_from("<H", data, offset)[0]


def _read_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def read_bmp(path: Path) -> BmpImage:
    data = path.read_bytes()
    if len(data) < 0x36 or data[:2] != b"BM":
        raise ValueError(f"{path} is not a valid 8-bit BMP file.")

    bit_count = _read_u16(data, 0x1C)
    compression = _read_u32(data, 0x1E)
    if bit_count != 8 or compression != 0:
        raise ValueError(f"{path} is not an uncompressed 8-bit BMP.")

    width = _read_u32(data, 0x12)
    height = _read_u32(data, 0x16)
    if width <= 0 or height <= 0:
        raise ValueError(f"{path} has invalid BMP dimensions.")

    info_header_size = _read_u32(data, 0xE)
    palette_offset = 14 + info_header_size
    pixel_offset = _read_u32(data, 0x0A)
    colors_used = _read_u32(data, 0x2E) or 256
    palette_size = max(1024, colors_used * 4)
    palette = data[palette_offset:palette_offset + palette_size]
    palette = palette[:colors_used * 4]
    if len(palette) < colors_used * 4:
        palette += b"\x00" * (colors_used * 4 - len(palette))

    row_stride = ((width + 3) // 4) * 4
    rows: list[bytes] = []
    for row in range(height):
        row_start = pixel_offset + row * row_stride
        row_data = data[row_start:row_start + width]
        rows.append(row_data)
    pixel_data = b"".join(rows)

    return BmpImage(
        path=path,
        width=width,
        height=height,
        palette=palette,
        pixel_data=pixel_data,
        colors_used=colors_used,
        transparent_index=0,
    )


def encode_rle_pixels(width: int, height: int, pixel_data: bytes, transparent_index: int = 0) -> bytes:
    row_stride = ((width + 3) // 4) * 4
    result = bytearray()
    run_length = 0

    for row in range(height - 1, -1, -1):
        row_start = row * row_stride
        for column in range(width):
            current = pixel_data[row_start + column]
            if current == transparent_index:
                run_length += 1
                if run_length == 255 or (row == 0 and column == width - 1):
                    result.extend((0x00, (run_length - 1) & 0xFF))
                    run_length = 0
            else:
                if run_length:
                    result.extend((0x00, (run_length - 1) & 0xFF, current))
                    run_length = 0
                else:
                    result.append(current)

    if run_length:
        result.extend((0x00, (run_length - 1) & 0xFF))
    return bytes(result)


def apply_bam_metadata(template: bytearray, *, width: int, height: int, x: int, y: int, data_offset: int, palette_offset: int, palette: bytes, raster: bytes) -> bytes:
    if len(template) < 0x10:
        raise ValueError("BAM template is too small.")

    frame_offset = _read_u32(template, 0x0C)
    if frame_offset == 0:
        raise ValueError("BAM template is missing a valid frame table.")

    struct.pack_into("<H", template, frame_offset, width)
    struct.pack_into("<H", template, frame_offset + 2, height)
    struct.pack_into("<H", template, frame_offset + 4, x)
    struct.pack_into("<H", template, frame_offset + 6, y)
    struct.pack_into("<I", template, frame_offset + 8, data_offset)

    if palette_offset + 1024 > len(template):
        template.extend(b"\x00" * (palette_offset + 1024 - len(template)))
    template[palette_offset:palette_offset + 1024] = palette[:1024]

    if data_offset + len(raster) > len(template):
        template.extend(b"\x00" * (data_offset + len(raster) - len(template)))
    template[data_offset:data_offset + len(raster)] = raster

    template[0:8] = b"BAMCV1  "
    struct.pack_into("<I", template, 8, data_offset + len(raster))
    return bytes(template)


def create_spell_bam(template_path: Path, bmp_path: Path, output_path: Path) -> Path:
    bmp = read_bmp(bmp_path)
    raster = encode_rle_pixels(bmp.width, bmp.height, bmp.pixel_data, bmp.transparent_index)

    template = bytearray(template_path.read_bytes())
    frame_offset = _read_u32(template, 0x0C)
    data_offset = _read_u32(template, frame_offset + 8)
    palette_offset = _read_u32(template, 0x10)
    sw = max(0, (bmp.width - 32) // 2)
    sh = max(0, (bmp.height - 32) // 2)

    bam = apply_bam_metadata(
        template,
        width=bmp.width,
        height=bmp.height,
        x=sw,
        y=sh,
        data_offset=data_offset,
        palette_offset=palette_offset,
        palette=bmp.palette,
        raster=raster,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(bam)
    return output_path


def find_pairing_large_file(large_path: Path, small_dir: Path) -> Path | None:
    base = large_path.stem[:-1]
    for candidate in sorted(small_dir.glob("*.bmp")):
        if candidate.stem == base + "S":
            return candidate
    for candidate in sorted(small_dir.glob("*.BMP")):
        if candidate.stem == base + "S":
            return candidate
    return None


def _normalize_palette(palette_1: bytes, palette_2: bytes) -> bytes:
    if len(palette_1) < 1024:
        palette_1 += b"\x00" * (1024 - len(palette_1))
    if len(palette_2) < 1024:
        palette_2 += b"\x00" * (1024 - len(palette_2))
    return palette_1[:1024]


def create_inventory_bam(template_path: Path, large_bmp_path: Path, small_bmp_path: Path, output_path: Path) -> Path:
    large = read_bmp(large_bmp_path)
    small = read_bmp(small_bmp_path)

    large_raster = encode_rle_pixels(large.width, large.height, large.pixel_data, large.transparent_index)
    small_raster = encode_rle_pixels(small.width, small.height, small.pixel_data, small.transparent_index)
    palette = _normalize_palette(large.palette, small.palette)

    template = bytearray(template_path.read_bytes())
    frame_offset = _read_u32(template, 0x0C)
    small_data_offset = _read_u32(template, frame_offset + 8)
    large_data_offset = small_data_offset + len(small_raster)
    palette_offset = _read_u32(template, 0x10)

    struct.pack_into("<H", template, frame_offset, small.width)
    struct.pack_into("<H", template, frame_offset + 2, small.height)
    struct.pack_into("<H", template, frame_offset + 4, max(0, (small.width - 32) // 2))
    struct.pack_into("<H", template, frame_offset + 6, max(0, (small.height - 32) // 2))
    struct.pack_into("<I", template, frame_offset + 8, small_data_offset)

    struct.pack_into("<H", template, frame_offset + 0x0C, large.width)
    struct.pack_into("<H", template, frame_offset + 0x0E, large.height)
    struct.pack_into("<H", template, frame_offset + 0x10, max(0, (large.width - 32) // 2))
    struct.pack_into("<H", template, frame_offset + 0x12, max(0, (large.height - 32) // 2))
    struct.pack_into("<I", template, frame_offset + 0x14, large_data_offset)

    if palette_offset + 1024 > len(template):
        template.extend(b"\x00" * (palette_offset + 1024 - len(template)))
    template[palette_offset:palette_offset + 1024] = palette[:1024]

    if small_data_offset + len(small_raster) > len(template):
        template.extend(b"\x00" * (small_data_offset + len(small_raster) - len(template)))
    template[small_data_offset:small_data_offset + len(small_raster)] = small_raster

    if large_data_offset + len(large_raster) > len(template):
        template.extend(b"\x00" * (large_data_offset + len(large_raster) - len(template)))
    template[large_data_offset:large_data_offset + len(large_raster)] = large_raster

    template[0:8] = b"BAMCV1  "
    struct.pack_into("<I", template, 8, large_data_offset + len(large_raster))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(bytes(template))
    return output_path


def iter_bmp_files(directory: Path) -> Iterable[Path]:
    for path in sorted(directory.glob("*.bmp")):
        yield path
    for path in sorted(directory.glob("*.BMP")):
        yield path
