from paraview.simple import *
from pathlib import Path
import sys
module_path = r"C:\Users\fw405\Documents\HiDEM_experiments\paraview"
if module_path not in sys.path:
    sys.path.append(module_path)
from anim_utils import *

glyph_path = get_source_path()
output_path = glyph_path.parent / f"animation.avi"

animationScene, timeKeeper, timesteps = setup_animation_scene()

save_animation_file(output_path)

print(f"AVI saved to: {output_path} ({len(timesteps)} frames)")
