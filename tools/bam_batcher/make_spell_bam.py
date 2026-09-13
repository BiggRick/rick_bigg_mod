#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from bam_batcher_common import create_spell_bam, iter_bmp_files


BASE_DIR = Path("tools") / "bam_batcher"


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert 8-bit BMP spell icons into BAM files using the same logic as the WeiDU batcher.")
    parser.add_argument("--input-dir", type=Path, default=BASE_DIR / "spell", help="Directory that contains source BMP files.")
    parser.add_argument("--output-dir", type=Path, default=BASE_DIR / "bam", help="Directory where generated BAM files are written.")
    parser.add_argument("--template", type=Path, default=BASE_DIR / "hdr-spl.bam", help="Template BAM used as the basis for spell BAM output.")
    args = parser.parse_args()

    if not args.template.exists():
        raise FileNotFoundError(f"Missing BAM template: {args.template}")
    args.input_dir.mkdir(parents=True, exist_ok=True)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    for source in iter_bmp_files(args.input_dir):
        target = args.output_dir / (source.stem + ".bam")
        create_spell_bam(args.template, source, target)
        print(f"Created {target.name} from {source.name}")


if __name__ == "__main__":
    main()
