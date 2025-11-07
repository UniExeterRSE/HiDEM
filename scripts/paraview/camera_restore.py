# ParaView Camera Restoration Code
# Copy and paste this code to restore the camera to the captured state

from paraview.simple import *

# Get the active view
view = GetActiveView()

# Get the camera
camera = view.GetActiveCamera()

# Set camera properties
camera.SetPosition(-2672.2914794014737, 503.065655479861, 826.4398153151898)
camera.SetFocalPoint(3585.151906331965, 241.10642400772693, -723.6909663280168)
camera.SetViewUp(0.24084201802517102, 0.010056571323560753, 0.9705122295606468)
camera.SetViewAngle(30.0)
camera.SetParallelProjection(0)
camera.SetParallelScale(1380.0635102910846)
camera.SetClippingRange(1764.0415349387488, 5656.287271248449)

# Update the view
view.Update()
Render()

print("Camera restored successfully!")
