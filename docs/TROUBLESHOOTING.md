[← Yuragi](../README.md) · [Documentation](README.md)

# Troubleshooting

## Playing but silent

If Play is active but silent, check both the selected output and the
**Quickshell application volume** in Omarchy's audio panel. The system remembers
that application volume separately from Yuragi's master and channel sliders.

## Old icons or controls after an update

Run `omarchy restart shell` to reload all QML components. This restarts the
desktop shell and pauses Yuragi; saved volumes and Randomize are preserved.

## Audio unavailable

A recording could not load. The other channels keep working. Reinstall Yuragi
to restore a damaged file, and check the [requirements](INSTALLATION.md).

## Paused icon is hidden

Hover the center of the bar. The icon stays visible while playing or while
the panel is open. See [Usage](USAGE.md).
