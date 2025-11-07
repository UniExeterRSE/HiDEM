from paraview.simple import *
from pathlib import Path


def get_source_path():
    """
    Return the Path of the first file-based source in the ParaView pipeline.
    
    Iterates through all sources in the pipeline and returns the file path
    of the first source that has a FileName property (e.g., readers for
    VTK, CSV, or other file formats).
    
    Returns
    -------
    pathlib.Path
        The file path of the first file-based source found in the pipeline.
    
    Raises
    ------
    RuntimeError
        If no file-based source is found in the pipeline.
    
    Notes
    -----
    This function handles different ParaView versions where FileName may be
    returned as a string, list, tuple, or property object with GetData().
    """
    sources = GetSources()
    for name, source in sources.items():
        proxy = FindSource(name[0])
        if hasattr(proxy, "FileName"):
            file_prop = proxy.FileName

            # Handle different return types for FileName property
            if isinstance(file_prop, (list, tuple)):
                filename = file_prop[0]
            elif isinstance(file_prop, str):
                filename = file_prop
            else:
                # Older ParaView (6.x) case where FileName is a property object
                filename = file_prop.GetData()[0] if hasattr(file_prop, "GetData") else None

            if filename:
                return Path(filename)

    raise RuntimeError("Could not determine glyph file path — check your sources.")


def setup_animation_scene():
    """
    Configure and return the animation scene for sequence playback.
    
    Sets up the ParaView animation scene to play through all timesteps in
    sequence mode, with one frame per timestep. The start and end times are
    set to match the available timestep range.
    
    Returns
    -------
    animationScene : ParaView AnimationScene
        The configured animation scene object.
    timeKeeper : ParaView TimeKeeper
        The time keeper object managing timesteps.
    timesteps : array-like
        Array of all available timestep values.
    
    Notes
    -----
    The animation scene is configured with:
    - PlayMode set to 'Sequence' for frame-by-frame playback
    - NumberOfFrames matching the number of timesteps
    - StartTime and EndTime spanning the full timestep range
    """
    animationScene = GetAnimationScene()
    timeKeeper = GetTimeKeeper()
    timesteps = timeKeeper.TimestepValues

    # Configure animation to play through all timesteps in sequence
    animationScene.PlayMode = 'Sequence'
    animationScene.NumberOfFrames = len(timesteps)
    animationScene.StartTime = timesteps[0]
    animationScene.EndTime = timesteps[-1]

    return animationScene, timeKeeper, timesteps


def save_animation_file(output_path, resolution=(1920, 1080), frame_rate=10):
    """
    Save an animation of the current view to a file.
    
    Exports the active render view as an animation file (e.g., AVI, MP4).
    The file format is determined by the extension of output_path.
    
    Parameters
    ----------
    output_path : str or pathlib.Path
        The output file path for the animation. The extension determines
        the file format (e.g., .avi, .mp4, .ogv).
    resolution : tuple of int, optional
        The (width, height) resolution in pixels for the output animation.
        Default is (1920, 1080) for Full HD.
    frame_rate : int, optional
        The frame rate (frames per second) for the output animation.
        Default is 10 fps.
    
    Notes
    -----
    The animation will render all frames defined in the current animation scene.
    Use setup_animation_scene() first to configure the timesteps to render.
    
    Examples
    --------
    >>> setup_animation_scene()
    >>> save_animation_file('output.avi', resolution=(3840, 2160), frame_rate=30)
    """
    renderView = GetActiveViewOrCreate('RenderView')
    SaveAnimation(str(output_path),
                  renderView,
                  ImageResolution=list(resolution),
                  FrameRate=frame_rate)

