#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from bam_batcher_common import create_inventory_bam, find_pairing_large_file, iter_bmp_files


BASE_DIR = Path("tools") / "bam_batcher"


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert the large/small inventory BMP pairs into combined BAM files using the same logic as the WeiDU batcher.")
    parser.add_argument("--large-dir", type=Path, default=BASE_DIR / "invlarge", help="Directory that contains the large inventory BMP files.")
    parser.add_argument("--small-dir", type=Path, default=BASE_DIR / "invsmall", help="Directory that contains the small inventory BMP files.")
    parser.add_argument("--output-dir", type=Path, default=BASE_DIR / "bam", help="Directory where generated BAM files are written.")
    parser.add_argument("--template", type=Path, default=BASE_DIR / "hdr-inv.bam", help="Template BAM used as the basis for inventory BAM output.")
    args = parser.parse_args()

    if not args.template.exists():
        raise FileNotFoundError(f"Missing BAM template: {args.template}")
    args.output_dir.mkdir(parents=True, exist_ok=True)

    for large in iter_bmp_files(args.large_dir):
        small = find_pairing_large_file(large, args.small_dir)
        if small is None:
            print(f"Skipping {large.name}: no matching small inventory BMP was found.")
            continue

        target = args.output_dir / (large.stem[:-1] + ".bam")
        create_inventory_bam(args.template, large, small, target)
        print(f"Created {target.name} from {large.name} + {small.name}")


if __name__ == "__main__":
    main()
