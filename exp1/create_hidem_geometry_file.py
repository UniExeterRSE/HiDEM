#!/usr/bin/env python3
import argparse
import numpy as np

def main():
    parser = argparse.ArgumentParser(
        description="Generate a HiDEM geometry file (x, y, surface, base, bed, friction, geom_mask)"
    )
    parser.add_argument("-o", "--output", default="geometry.dat",
                        help="Output filename (default: geometry.dat)")
    parser.add_argument("--xsize", type=float, default=2000.0,
                        help="Domain size in x-direction (m, default: 2000)")
    parser.add_argument("--ysize", type=float, default=4000.0,
                        help="Domain size in y-direction (km, default: 4000)")
    parser.add_argument("--nx", type=int, default=81,
                        help="Number of grid points in x-direction (default: 81)")
    parser.add_argument("--ny", type=int, default=161,
                        help="Number of grid points in y-direction (default: 161)")
    parser.add_argument("--ice_length", type=float, default=1000.0,
                        help="Length of ice sheet along y (m, default: 1000)")
    parser.add_argument("--height_inland", type=float, default=300.0,
                        help="Inland ice surface height (m, default: 300)")
    parser.add_argument("--height_ocean", type=float, default=200.0,
                        help="Ocean-facing ice surface height (m, default: 200)")
    parser.add_argument("--include_mask", action="store_true",
                        help="Include geom_mask column (ice=1, ocean=2, bedrock=0)")

    args = parser.parse_args()

    # Grid coordinates
    x = np.linspace(0, args.xsize, args.nx)
    y = np.linspace(0, args.ysize, args.ny)
    xm, ym = np.meshgrid(x, y)

    # Initialize arrays
    surface = np.zeros_like(xm)
    base = np.zeros_like(xm)
    bed = np.zeros_like(xm)
    friction = np.zeros_like(xm)
    geom_mask = np.zeros_like(xm)

    # Ice region: y < ice_length
    ice_mask = ym < args.ice_length

    # Linear gradient in ice height
    surface[ice_mask] = np.interp(
        ym[ice_mask],
        [0, args.ice_length],
        [args.height_inland, args.height_ocean]
    )

    # Base and bed = 0 throughout
    base[:] = 0.0
    bed[:] = 0.0

    # Friction = 1 in ice, 0 elsewhere
    friction[ice_mask] = 1.0
    friction[~ice_mask] = 0.0

    # geom_mask: 1 for ice, 2 for ocean
    geom_mask[ice_mask] = 1
    geom_mask[~ice_mask] = 2

    # Flatten for output
    num_points = args.nx * args.ny

    with open(args.output, "w") as f:
        f.write(f"{num_points}\n")
        if args.include_mask:
            for xi, yi, si, bi, be, fr, gm in zip(
                xm.ravel(), ym.ravel(), surface.ravel(),
                base.ravel(), bed.ravel(), friction.ravel(), geom_mask.ravel()
            ):
                f.write(f"{xi: .18e}\t{yi: .18e}\t{si: .18e}\t{bi: .18e}\t{be: .18e}\t{fr: .18e}\t{int(gm)}\n")
        else:
            for xi, yi, si, bi, be, fr in zip(
                xm.ravel(), ym.ravel(), surface.ravel(),
                base.ravel(), bed.ravel(), friction.ravel()
            ):
                f.write(f"{xi: .18e}\t{yi: .18e}\t{si: .18e}\t{bi: .18e}\t{be: .18e}\t{fr: .18e}\n")

    print(f" Geometry file written to {args.output} ({num_points} points)")
    if args.include_mask:
        print("   Included geom_mask column (ice=1, ocean=2)")

if __name__ == "__main__":
    main()
