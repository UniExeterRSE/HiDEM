from paraview.simple import *

# Get the animation scene and time information
animationScene = GetAnimationScene()
timeKeeper = GetTimeKeeper()

# Get all available timesteps
timesteps = timeKeeper.TimestepValues
print(f"Found {len(timesteps)} timesteps: {timesteps}")

# Configure the animation to play through all timesteps
animationScene.PlayMode = 'Sequence'
animationScene.NumberOfFrames = len(timesteps)  # One frame per timestep
animationScene.StartTime = timesteps[0]
animationScene.EndTime = timesteps[-1]

# Get render view
renderView1 = GetActiveViewOrCreate('RenderView')

# Now save the animation
SaveAnimation('C:/Users/fw405/PycharmProjects/HiDEM/test/Paraview/frame.png', 
              renderView1,
              ImageResolution=[1920, 1080],
              FrameRate=10)

print(f"Animation saved! Should have {len(timesteps)} frames.")