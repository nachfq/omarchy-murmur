# Publish Yuragi

## Release 1.0.0

The initial ten PRs are merged into `main`; the final combined commit
`4902e0818f4382658e2f1600625ebe00ccf8fd38` passed CI on 2026-09-15.
Future changes should stay in focused PRs for maintainer review and merge.

A release can be tagged `v1.0.0` from a validated commit on `main`.
Do not publish a tag from an unmerged feature branch.
Use the release notes below; validate installation from the public default
branch before requesting the marketplace listing.

## Marketplace submission

Follow the [official publishing guide](https://plugins.omarchy.org/publish.html)
and its **Submit your plugin** link. The listing is prepared here; no submission
has been sent on the maintainer's behalf.

| Field | Value |
| --- | --- |
| Repository | https://github.com/nachfq/omarchy-yuragi |
| Name | Yuragi |
| Plugin ID | `nachfq.yuragi` |
| Author | Nacho fq |
| Version | `1.0.0` |
| Description | An offline ambient sound mixer with ten sounds and gentle volume drift. |
| Category | Productivity |
| Tags | Media, Bar, Quickshell |
| Preview | `preview.png` in the repository root |
| License | MIT code; CC0, CC BY 4.0 and public-domain recordings, documented individually |
| Runtime | Omarchy Shell / Quickshell, Qt Multimedia 6.11+ with native PipeWire audio |
| Network / privileges | None during playback; no install hooks or privileged commands |

The [submission form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml)
currently asks for a repository URL, category, one to three tags, optional notes
and ownership/install checkboxes. It does not ask the submitter for a commit
SHA; automated validation checks the repository's current commit. Confirm the
final code is on the default branch before submitting.

Suggested maintainer notes: “Native QML/Quickshell ambient mixer. Requires
Qt Multimedia 6.11+ with the native PipeWire backend. No installation hooks,
privileged operations or network access during playback. The GitHub footer
button opens the repository only when clicked. Sound sources and licenses are
documented in SOUNDS_LICENSES.md.”

Still required: a clean install/remove check from the merged default branch,
and submission/review. A `v1.0.0` release is our release step,
not a requirement listed in the marketplace guide. Donation setup is optional
and does not block listing.

## Release notes

Yuragi brings ten offline ambient sounds to Omarchy's bar. Mix independent
channel volumes with a dedicated master, pause/resume the whole mix, or turn
on gentle Randomize drift. The compact panel follows your theme and supports
keyboard controls. Preferences return paused after restarting the shell.
Play and Pause fade over 600 ms; pausing releases decoded recordings from memory.

Recordings include rain, thunder, waves, wind, fire, birds, crickets, coffee
shop, singing bowl and white noise, with individual credits and licenses.

## Donations

GitHub Sponsors onboarding was submitted by the maintainer and is awaiting
review as of 2026-09-15. Keep the README’s Support section prominent; add the
funding link there once the listing is active.

When the maintainer supplies a real payment URL, add it to the README's Support
section and `.github/FUNDING.yml` using the matching provider key or `custom`.
Do not create a payment account, invent a URL, or add a donation control to the
panel. Donations do not unlock features.

Options checked on 2026-09-15:

- [GitHub Sponsors](https://docs.github.com/en/sponsors/getting-started-with-github-sponsors/about-github-sponsors)
  supports Argentina and fits the international open-source audience. Receiving
  requires onboarding and payout verification; personal-account sponsorships
  carry no GitHub platform fee. Set up an account before adding its funding link.
  Its [payout terms](https://docs.github.com/en/site-policy/github-terms/github-sponsors-additional-terms#33-payment-timing)
  include a 60-day initial waiting period; later payouts follow the configured
  monthly schedule and any cross-border minimums/conversion conditions.
- [Cafecito](https://cafecito.app/faq/como-configurar-mis-medios-de-cobro)
  connects to Mercado Pago for a local contribution link. Its current FAQ
  discloses fees in the platform/payment flow, rather than promising one fixed rate.
- [Lemon Squeezy's policy](https://docs.lemonsqueezy.com/help/getting-started/prohibited-products)
  prohibits donations without a product or priced above the product's value.
  Do not create a donation-only checkout for Yuragi in the existing app store.
