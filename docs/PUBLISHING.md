# Publish Murmur

## Release 1.0.0

Merge the three PRs in order: foundation → mixer → release documentation.
This repository uses merge commits and deletes merged branches automatically.
That preserves the stacked commits and lets GitHub retarget each dependent PR
to `main` when its base branch is deleted. Check the base shown before merging.
CI must pass on the final combined commit. The maintainer performs all merges.
See [GitHub's branch handling](https://docs.github.com/en/pull-requests/how-tos/commit-changes/managing-branches-within-your-repository).

After the final merge, an agent can tag that merged commit `v1.0.0` and create
a GitHub release. Do not publish a tag from an unmerged feature branch.
Use the release notes below; validate installation from the public default
branch before requesting the marketplace listing.

## Marketplace submission

Follow the [official publishing guide](https://plugins.omarchy.org/publish.html)
and its **Submit your plugin** link. The listing is prepared here; no submission
has been sent on the maintainer's behalf.

| Field | Value |
| --- | --- |
| Repository | https://github.com/nachfq/omarchy-murmur |
| Name | Murmur |
| Plugin ID | `nachfq.murmur` |
| Author | Nacho fq |
| Version | `1.0.0` |
| Description | An offline ambient sound mixer with ten sounds and gentle volume drift. |
| Tags | audio, ambient, offline, bar, quickshell |
| Preview | `preview.png` in the repository root |
| License | MIT code; CC0, CC BY 4.0 and public-domain recordings, documented individually |
| Runtime | Omarchy Shell / Quickshell, Qt Multimedia with FFmpeg backend |
| Network / privileges | None during playback; no install hooks or privileged commands |

Select the form's current audio/media category. Submit the exact merged commit
SHA required by the form; marketplace verification applies to that snapshot.

## Release notes

Murmur brings ten offline ambient sounds to Omarchy's bar. Mix independent
channel volumes with a dedicated master, pause/resume the whole mix, or turn
on gentle Randomize drift. The compact panel follows your theme and supports
keyboard controls. Preferences return paused after restarting the shell.

Recordings include rain, thunder, waves, wind, fire, birds, crickets, coffee
shop, singing bowl and white noise, with individual credits and licenses.

## Donations

When the maintainer supplies a real payment URL, add it to the README's Support
section and `.github/FUNDING.yml` using the matching provider key or `custom`.
Do not create a payment account, invent a URL, or add a donation control to the
panel. Donations do not unlock features.
