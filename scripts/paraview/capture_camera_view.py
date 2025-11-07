# Import ParaView Simple module
from paraview.simple import *
import os

os.chdir('C:\\Users\\fw405\\Documents\\HiDEM_experiments\\paraview')

# Get the active view
view = GetActiveView()

# Get the camera object
camera = view.GetActiveCamera()

# Capture all camera properties
position = camera.GetPosition()
focal_point = camera.GetFocalPoint()
view_up = camera.GetViewUp()
view_angle = camera.GetViewAngle()
parallel_projection = camera.GetParallelProjection()
parallel_scale = camera.GetParallelScale()
clipping_range = camera.GetClippingRange()

# Generate the restoration code
restore_code = f"""# ParaView Camera Restoration Code
# Copy and paste this code to restore the camera to the captured state

from paraview.simple import *

# Get the active view
view = GetActiveView()

# Get the camera
camera = view.GetActiveCamera()

# Set camera properties
camera.SetPosition({position[0]}, {position[1]}, {position[2]})
camera.SetFocalPoint({focal_point[0]}, {focal_point[1]}, {focal_point[2]})
camera.SetViewUp({view_up[0]}, {view_up[1]}, {view_up[2]})
camera.SetViewAngle({view_angle})
camera.SetParallelProjection({int(parallel_projection)})
camera.SetParallelScale({parallel_scale})
camera.SetClippingRange({clipping_range[0]}, {clipping_range[1]})

# Update the view
view.Update()
Render()

print("Camera restored successfully!")
"""

# Print the restoration code
print("\n" + "="*70)
print("CAMERA STATE CAPTURED")
print("="*70)
print(restore_code)
print("="*70)

# Optionally, save to a file
output_file = "camera_restore.py"
with open(output_file, 'w') as f:
    f.write(restore_code)

print(f"\nRestoration code also saved to: {output_file}")

