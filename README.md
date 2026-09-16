# 3d-models

OpenSCAD sources and renders. Each directory is one model with its own README, source, and `out/` with the STL and preview of every part. `./build` regenerates `out/` from source and CI rejects a stale one; the contract is in [AGENTS.md](AGENTS.md).

| model | description | thumbnail |
|---|---|---|
| [hopper](hopper) | Parametric seed hopper for a green-cheek conure feeder: wedge body filling a 140 × 170 mm cage door, ~1 L, refilled from outside, hull-lipped tray with perch. One spec, several models' answers. | [![hopper](hopper/codex/out/assembly.png)](hopper) |
| [hopper critic loop](hopper/critic-loop) | Six clean-room hopper runs comparing one-shot delivery with capped independent-critic loops. | [![critic loop](hopper/critic-loop/B2/out/assembly.png)](hopper/critic-loop) |
| [hopper v3](hopper/v3) | Two one-piece small-door conure hoppers: a rail-saddle plane-flow wedge and a snap-flange inclined magazine. | [![hopper v3](hopper/v3/candidate-a/out/candidate_a.png)](hopper/v3) |
| [med-tracker](med-tracker) | Two-medicine infant dose dial with 24-position peg rings, bottle wells, syringe holders, and large AM/PM numerals. | [![med-tracker](med-tracker/out/assembly.png)](med-tracker) |
| [skyrim-horn](skyrim-horn) | Original Nordic-fantasy curved horn LED tea-light holder with a raised-hexagon two-screw wall mount and long centered arm. | [![skyrim-horn](skyrim-horn/out/assembly.png)](skyrim-horn) |
| [horn candle](horn-candle) | Two printer-ready A1 mini plates for the horn candle table decoration. | [![horn candle](horn-candle/horn-candle-plate-1.png)](horn-candle) |
| [Lumen Relay low-poly avatar](avatar/low-poly) | Original 520-triangle translucent VRM 1.0 humanoid with nine voice-state clips and nine facial shapes. | [![Lumen Relay](avatar/low-poly/proof/idle_breathing.png)](avatar/low-poly) |
| [Aster Echo reasonable-poly avatar](avatar/reasonable-poly) | Original 28,080-triangle translucent VRM 1.0 humanoid with 55 mapped bones, nine voice-state clips and nine facial shapes. | [![Aster Echo](avatar/reasonable-poly/proof/idle_breathing.png)](avatar/reasonable-poly) |

MIT, see [LICENSE](LICENSE).
