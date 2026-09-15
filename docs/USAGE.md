[← Yuragi](../README.md) · [Documentation](README.md)

# Usage

- Hover the center of the bar to reveal Yuragi's paused, dimmed wave icon
  before the clock. While playing, it stays visible in the normal theme color,
  like Omarchy's status indicators. An open panel keeps its icon visible.
- Click the wave icon to open the panel. Click again, click
  outside, or press Escape to close it. Closing does not stop the sounds.
- **Play / Pause** controls the whole mix. A channel at zero is off. With every
  channel off, Play is disabled until you raise one.
  Playback fades in and out over 600 ms. Clicking again during a fade reverses
  it smoothly; the master and channel sliders keep their chosen values.
- **Master** changes only Yuragi. The operating system volume remains separate.
- **Randomize** shows On / Off; only On has a filled background. Hover and
  keyboard focus use an outline. Drift runs during playback. Each active
  sound drifts within ±25% of its chosen volume over independent 15–30 second
  transitions. Zero-volume sounds stay off.
- Sliders follow the audible mix. Dragging one sets a new base volume and
  temporarily holds that channel. Turning Randomize off gently returns the
  mix to the chosen base volumes.
- Tab / Shift+Tab move through controls. Arrow keys adjust the focused slider;
  Home / End set zero / full volume. Space or Enter activates a focused button.
  Clicking a slider focuses it; its mouse wheel then adjusts that slider.
- The GitHub icon at the bottom right opens this repository in your default
  browser. Closing the panel to follow the link keeps your mix playing.

The first mix has rain at 40%, master at 50%, and Randomize off. Preferences are
stored in Yuragi's own bar entry in `~/.config/omarchy/shell.json`. Restarting
the shell/session restores the mix **paused**. Random movement is not written
to disk. Pause fades out, stops all voices and releases decoded recordings.
Play reloads and restarts the recordings from the beginning,
keeping your volumes and Randomize setting. Removing the bar entry through disable/remove may discard its settings,
as with other Omarchy inline widget preferences.

The shared service owns the live mix. Changes are saved after you finish an
interaction; delayed file notifications cannot rewind it. If you edit Yuragi's
settings in `shell.json` by hand, reload the shell to apply them.

One shared audio service serves all bar instances. Qt mixes all active sounds
into a single system audio stream. Audio follows the system's
default output, including changes between headphones and speakers. Sounds are
calibrated with fixed headroom so all ten can play together without clipping.
