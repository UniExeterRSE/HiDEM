#!/usr/bin/env python3
"""
Convert a VTU file with appended binary data to CSV.

Usage:
    python vtu_to_csv.py -i input_file.vtu
"""

import re
import struct
import argparse
import sys
import logging
from pathlib import Path
import numpy as np

logging.basicConfig(level=logging.INFO, format="%(message)s")

TYPE_RE = re.compile(r'type="([A-Za-z0-9]*)"')
OFFSET_RE = re.compile(r'offset="([0-9]*)"')
ENDIAN_RE = re.compile(r'byte_order="([A-Za-z]*)"')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert VTU binary appended data to CSV.")
    parser.add_argument("-i", "--input", required=True, help="Input VTU file")
    parser.add_argument("-o", "--output", help="Output CSV file (optional)")
    return parser.parse_args()


def detect_endianness(label: str) -> str:
    label = label.lower()
    if "little" in label:
        return "<"
    elif "big" in label:
        return ">"
    raise ValueError(f"Unrecognized endianness: {label}")


def detect_float_format(float_type: str, endian_prefix: str) -> tuple[str, int]:
    if "32" in float_type:
        dtype = np.dtype(endian_prefix + "f4")
    elif "64" in float_type:
        dtype = np.dtype(endian_prefix + "f8")
    else:
        raise ValueError(f"Unrecognized float format: {float_type}")
    return dtype, dtype.itemsize


def main() -> None:
    args = parse_args()
    infile = Path(args.input)
    if not infile.exists():
        sys.exit(f"Error: input file '{infile}' not found.")

    outfile = Path(args.output) if args.output else infile.with_suffix(".csv")

    with infile.open("rb") as indata:
        float_type = None
        point_offset = None
        endianness = None

        # Read header
        for line in indata:
            line_str = line.decode("utf-8", errors="ignore")
            if "Position" in line_str:
                float_type = TYPE_RE.search(line_str).group(1)
                point_offset = OFFSET_RE.search(line_str).group(1)
                logging.info(f"Detected float type: {float_type}, offset: {point_offset}")
            if "<VTKFile" in line_str:
                endianness = ENDIAN_RE.search(line_str).group(1)
            if "<Appended" in line_str:
                break

        if not (float_type and endianness):
            sys.exit("Error: could not detect data format or endianness from VTU header.")

        logging.info(f"Reading data in {float_type} format ({endianness} endian) from {infile}")

        # Skip the '_' symbol that starts appended data
        indata.read(1)
        bytecount = struct.unpack("i", indata.read(4))[0]

        endian_prefix = detect_endianness(endianness)
        dtype, size = detect_float_format(float_type, endian_prefix)
        num_count = bytecount // size

        np_data = np.fromfile(indata, dtype=dtype, count=num_count).reshape((-1, 3))

    np.savetxt(outfile, np_data, fmt="%.6f", delimiter=",")
    logging.info(f"Saved CSV data to {outfile}")


if __name__ == "__main__":
    main()
