# ParaView Camera Restoration Code
# Copy and paste this code to restore the camera to the captured state

from paraview.simple import *

# Get the active view
view = GetActiveView()

# Get the camera
camera = view.GetActiveCamera()

# Set camera properties
camera.SetPosition(-1586.28890832377, 457.60165662932536, 557.4088532118229)
camera.SetFocalPoint(3585.151906331965, 241.10642400772693, -723.6909663280168)
camera.SetViewUp(0.24084201802517102, 0.010056571323560753, 0.9705122295606468)
camera.SetViewAngle(30.0)
camera.SetParallelProjection(0)
camera.SetParallelScale(1380.0635102910846)
camera.SetClippingRange(5.139152264863893, 5139.152264863893)

# Update the view
view.Update()
Render()

print("Camera restored successfully!")
