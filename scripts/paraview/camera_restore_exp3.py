# ParaView Camera Restoration Code
# Copy and paste this code to restore the camera to the captured state

from paraview.simple import *

# Get the active view
view = GetActiveView()

# Get the camera
camera = view.GetActiveCamera()

# Set camera properties
camera.SetPosition(-3081.412985967285, 2641.9872523056974, 624.8705538153938)
camera.SetFocalPoint(1612.9199003382603, 1306.5105895656282, 376.9219974746036)
camera.SetViewUp(0.049092835248600704, -0.012857546512533232, 0.9987114583426646)
camera.SetViewAngle(30.0)
camera.SetParallelProjection(0)
camera.SetParallelScale(1045.3069112573871)
camera.SetClippingRange(2369.5042314289194, 6692.74214620715)

# Update the view
view.Update()
Render()

print("Camera restored successfully!")
