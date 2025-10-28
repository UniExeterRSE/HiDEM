from paraview.simple import *

animationScene = GetAnimationScene()
timeKeeper = GetTimeKeeper()
timesteps = timeKeeper.TimestepValues

animationScene.PlayMode = 'Sequence'
animationScene.NumberOfFrames = len(timesteps)
animationScene.StartTime = timesteps[0]
animationScene.EndTime = timesteps[-1]

renderView1 = GetActiveViewOrCreate('RenderView')

# Try AVI with proper setup
SaveAnimation('C:/Users/fw405/PycharmProjects/HiDEM/test/Paraview/animation.avi',
              renderView1,
              ImageResolution=[1920, 1080],
              FrameRate=10)

print("AVI saved!")
