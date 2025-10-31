#!/usr/bin/env python3
import argparse
import numpy as np
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(
        description="Generate a HiDEM geometry file (columns are: x, y, surface, base, bed, friction[, geom_mask])"
    )
    parser.add_argument("-o", "--output", default="geometry.dat",
                        help="Output filename (default: geometry.dat)")
    parser.add_argument("--xstart", type=float, default=-100.0,
                        help="Start of domain in x-direction (m, default: -100)")
    parser.add_argument("--xend", type=float, default=1600.0,
                        help="End of domain in x-direction (m, default: 1600)")
    parser.add_argument("--ystart", type=float, default=0.0,
                        help="Start of domain in y-direction (m, default: 0)")
    parser.add_argument("--yend", type=float, default=4000.0,
                        help="End of domain in y-direction (m, default: 4000)")
    parser.add_argument("--dx", type=float, default=25.0,
                        help="Grid spacing in metres (default: 25)")
    parser.add_argument("--ice_length", type=float, default=1000.0,
                        help="Length of ice sheet along y (m, default: 1000)")
    parser.add_argument("--height_inland", type=float, default=300.0,
                        help="Inland ice surface height (m, default: 300)")
    parser.add_argument("--height_ocean", type=float, default=200.0,
                        help="Ocean-facing ice surface height (m, default: 200)")
    parser.add_argument("--include_mask", action="store_true",
                        help="Include geom_mask column (ice=1, ocean=2, bedrock=0)")

    args = parser.parse_args()

    # Print parameter values
    print("=" * 60)
    print("Parameter values:")
    print("=" * 60)
    print(f"  Output file:        {args.output}")
    print(f"  X-domain:           {args.xstart} to {args.xend} m")
    print(f"  Y-domain:           {args.ystart} to {args.yend} m")
    print(f"  Grid spacing (dx):  {args.dx} m")
    print(f"  Ice length:         {args.ice_length} m")
    print(f"  Height inland:      {args.height_inland} m")
    print(f"  Height ocean:       {args.height_ocean} m")
    print(f"  Include mask:       {args.include_mask}")
    print("=" * 60)
    print()

    output_file = Path(args.output)

    # Derive grid size from spacing
    nx = int(round((args.xend - args.xstart) / args.dx)) + 1
    ny = int(round((args.yend - args.ystart) / args.dx)) + 1

    # Generate coordinate grid
    x = np.linspace(args.xstart, args.xend, nx)
    y = np.linspace(args.ystart, args.yend, ny)
    xm, ym = np.meshgrid(x, y)

    # Initialize arrays
    surface = np.zeros_like(xm)
    base = np.zeros_like(xm)
    bed = np.zeros_like(xm)
    friction = np.zeros_like(xm)
    geom_mask = np.zeros_like(xm)

    # Ice region: y < ice_length
    ice_mask = ym < args.ice_length

    # Linear gradient in ice surface height
    surface[ice_mask] = np.interp(
        ym[ice_mask],
        [0, args.ice_length],
        [args.height_inland, args.height_ocean]
    )

    surface[xm < args.xstart + args.dx] = 0.0
    surface[xm > args.xend - args.dx] = 0.0

    # Base and bed = 0 throughout
    base[:] = 0.0
    bed[:] = 0.0

    # Friction = 1000 in ice, 0 elsewhere
    friction[ice_mask] = 1000.0
    friction[~ice_mask] = 0.0

    # geom_mask: 1 for ice, 2 for ocean
    geom_mask[ice_mask] = 1
    geom_mask[~ice_mask] = 2

    # Flatten for output
    num_points = nx * ny

    with open(output_file, "w") as f:
        f.write(f"{num_points}\n")
        if args.include_mask:
            for xi, yi, si, bi, be, fr, gm in zip(
                xm.ravel(), ym.ravel(), surface.ravel(),
                base.ravel(), bed.ravel(), friction.ravel(), geom_mask.ravel()
            ):
                f.write(f"{xi: .18e} {yi: .18e} {si: .18e} {bi: .18e} {be: .18e} {fr: .18e} {int(gm)}\n")
        else:
            for xi, yi, si, bi, be, fr in zip(
                xm.ravel(), ym.ravel(), surface.ravel(),
                base.ravel(), bed.ravel(), friction.ravel()
            ):
                f.write(f"{xi: .18e} {yi: .18e} {si: .18e} {bi: .18e} {be: .18e} {fr: .18e}\n")

    print(f"Geometry file written to {output_file.resolve()}")
    print(f"  Domain: {args.xend - args.xstart:.0f} m × {args.yend - args.ystart:.0f} m ({args.xstart} → {args.xend}, {args.ystart} → {args.yend})")
    print(f"  Grid spacing: {args.dx:.1f} m  →  {nx} × {ny} points  ({num_points:,} total)")
    if args.include_mask:
        print("  Included geom_mask column (ice=1, ocean=2)")

if __name__ == "__main__":
    main()
