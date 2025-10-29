from paraview.simple import *
from pathlib import Path


def get_source_path():
    """Return the Path of the first file-based source in the ParaView pipeline."""
    sources = GetSources()
    for name, source in sources.items():
        proxy = FindSource(name[0])
        if hasattr(proxy, "FileName"):
            file_prop = proxy.FileName

            if isinstance(file_prop, (list, tuple)):
                filename = file_prop[0]
            elif isinstance(file_prop, str):
                filename = file_prop
            else:
                # Older ParaView (6.x) case
                filename = file_prop.GetData()[0] if hasattr(file_prop, "GetData") else None

            if filename:
                return Path(filename)

    raise RuntimeError("Could not determine glyph file path — check your sources.")


def setup_animation_scene():
    """Return (animationScene, timeKeeper, timesteps) configured for sequence playback."""
    animationScene = GetAnimationScene()
    timeKeeper = GetTimeKeeper()
    timesteps = timeKeeper.TimestepValues

    animationScene.PlayMode = 'Sequence'
    animationScene.NumberOfFrames = len(timesteps)
    animationScene.StartTime = timesteps[0]
    animationScene.EndTime = timesteps[-1]

    return animationScene, timeKeeper, timesteps


def save_animation_file(output_path, resolution=(1920, 1080), frame_rate=10):
    """Save an animation to the specified file path."""
    renderView = GetActiveViewOrCreate('RenderView')
    SaveAnimation(str(output_path),
                  renderView,
                  ImageResolution=list(resolution),
                  FrameRate=frame_rate)

glyph_path = get_source_path()
output_path = glyph_path.parent / "frame.png"

animationScene, timeKeeper, timesteps = setup_animation_scene()

save_animation_file(output_path)

print(f"Animation frames saved to: {output_path.parent} ({len(timesteps)} frames)")
