# Resource measurements

Measured 2026-09-15 on an Intel Core i5-1135G7 (4 cores / 8 threads), about
15.3 GiB RAM, Omarchy 4.0.3, Qt 6.11.2 and Quickshell 0.3.1.

## Method

`scripts/measure_resources.py` loads the actual service in a separate
Quickshell process, on a private native PipeWire server with a null output.
No desktop defaults or physical speakers are touched. Each state settles for
3 seconds, then CPU ticks are sampled for 15 seconds; RSS/PSS are read from
`/proc/<pid>/smaps_rollup` at the end. Two fresh processes repeat the final
sequence. Active voice counts and completed fade-in are checked before sampling.

The panel is closed/not rendered. This measures playback and drift, not popup
rendering, peak startup CPU, battery draw or the whole desktop shell. CPU is
percent of **one logical core**. RSS includes shared libraries in full; PSS
apportions shared pages. These are total isolated-process numbers, not amounts
to add to the running Omarchy process, which already hosts Qt and other plugins.
The desktop remained in ordinary use; CPU frequency and allocator/page residency
were not fixed. Treat ranges as observations, not a universal benchmark.

## Final implementation

| State | CPU, one core | RSS, MiB | PSS, MiB |
| --- | ---: | ---: | ---: |
| Empty Quickshell harness | 0–0.07% | 63.8–63.9 | 36.5 |
| Service loaded, before playback | below sample resolution | 115.3–115.4 | 72.4–72.5 |
| Rain only | 0.27–0.46% | 111.4–125.3 | 67.8–81.8 |
| Ten sounds | 0.40–0.60% | 173.2–180.6 | 129.6–137.1 |
| Ten sounds + Randomize | 1.80–2.00% | 173.3–179.9 | 129.7–136.4 |
| Paused after all ten | below sample resolution | 109.4–115.0 | 66.3–71.9 |

A zero CPU result means no additional ticks were resolved over the sample, not
that the process can never wake. Lower rain/paused RSS than initial idle can
reflect reclamation of temporary initialization allocations and mapped pages.

## Finding and change

Before this change, a development baseline retained **173.1 MiB RSS** after
pausing all ten sounds, almost exactly the playing value. The final version
clears each stopped SoundEffect source after its fade reaches silence. In the
two final runs, pausing returned **64.9 and 63.9 MiB RSS** within the same process
(and a similar amount of PSS). Resume reloads the recordings; restarts from the
beginning were already part of the plugin's behavior.

This is a memory improvement, not a demonstrated CPU improvement. The earlier
single development baseline showed about 1% CPU with Randomize; the final runs
showed 1.8–2%. The baseline overlapped some validation work and the environment
was not controlled enough to attribute an exact CPU difference. Normal gain
interpolation remains in Qt rather than doing every animation frame in QML.

CPU usage is small on this machine. Active sample RAM is material for a small
utility, but predictable for ten uncompressed, preloaded recordings. The most
useful low-complexity improvement was releasing it when unused; that is now
implemented. The shipped audio still occupies about **36 MiB** on disk.

Further memory reductions would require shorter loops (more audible repetition)
or a streaming/codec change (a different audio architecture). Neither is needed
to fix the pause retention, and neither was applied. Drift work could be reduced
by updating less often, but that trades away temporal smoothness and should be
measured before changing the working controls.

[Raw measurements](performance.json) include the earlier baseline and both final
runs. Reproduce with:

```sh
scripts/with_test_audio.sh python3 scripts/measure_resources.py --output /tmp/yuragi-resources.json
```
