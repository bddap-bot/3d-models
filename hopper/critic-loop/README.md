# Critic-loop experiment

Six clean-room seed-hopper runs tested whether an independent critic loop improved a first-pass design. A1 and A2 were controls with one delivery and no critic. B1 and B2 allowed at most three rounds; C1 and C2 allowed at most sixteen. After each round below 8/10, the maker was to address the ranked issues and submit the whole design to a new critic. A score of 8 ended the loop. The [critic prompt](critic-prompt.md) is preserved verbatim.

Only five designs exist: B1 and C1 were truncated after an out-of-memory failure, and C2 was censored before its first delivery. “Rounds” counts completed critic responses.

| run | arm | rounds | critic trajectory | audit | my score | parts | assembly | report |
|---|---|---:|---|---|---:|---:|---|---|
| A1 | control | 0 | — | CLEAN | 4 | 3 | [STL](A1/out/assembly.stl) | [report](A1/REPORT.md) |
| A2 | control | 0 | — | LEAK | 6 | 4 | [STL](A2/out/assembly.stl) | [report](A2/REPORT.md) |
| B1 | cap 3, TRUNCATED | 0 | no score returned | CLEAN, prompt intact | 5 | 4 | [STL](B1/out/assembly.stl) | [report](B1/REPORT.md) |
| B2 | cap 3 | 3 | 3 → 5 → 5 | CLEAN, prompt intact | 5 | 3 | [STL](B2/out/assembly.stl) | [report](B2/REPORT.md) |
| C1 | cap 16, TRUNCATED | 1 | 3 | CLEAN, prompt intact | 3 | 4 | [STL](C1/out/assembly.stl) | [report](C1/REPORT.md) |
| C2 | cap 16, CENSORED | 0 | — | not audited | — | 0 | not delivered | not delivered |

## Analysis

Independent mesh inspection found all 18 printable parts watertight, single-body, and within 175 mm. Measured cavity capacities were A1 0.978 L, A2 1.006 L, B1 1.006 L, B2 0.997 L, and C1 1.000 L; reported full-width slots were respectively 98, 50, 72, 80, and 52 mm, meeting the 50 mm floor. The basic geometry requirements were therefore easy for every delivered run. Physical integration was not: A1’s cage model intersects its lid/front plate; A2 knowingly violates layer direction and needs supports; B1 never obtained a completed critic response; B2 retained an uninsertable/jamming tray detent, difficult lid snap, high support use, no seed shutoff, and wrong layer direction after three rounds; C1’s first critic found no installation path, cover/lid collisions, zero tray clearance, poor feeding access, and no shutoff.

B2 shows what the loop bought. Round 1 ranked the captive tray first, then found an impossible latch, unusable perch, mismatched slicer comparison, and heavy supports. The revision deleted the latch, moved the perch, freed the tray and corrected the slice comparison. Round 2 ranked the open cage-door area first, then found weak retention, a bad print pose and a square lip; the revision added a shroud, tightened retention, changed pose and rounded the lip. Round 3 ranked the newly reversed tray detent first. Score improved 3→5, then plateaued: the final pass exposed fresh assembly faults in those revisions. The three-round cap, not the 8/10 bar, stopped it. Critics repeatedly regenerated meshes, rendered views, and measured intersections rather than trusting reports.

The experiment cannot establish that a 16-round cap improves quality. C1 stopped during its first revision and C2 produced no design. Operationally, both critic-loop arms lost a run to the 18 GB limit: B1 and C1 died inside Python/trimesh mesh verification; C1 scratch shows dense ray/intersection/kinematic work, while B1’s durable files do not identify a narrower recipe, so no stronger cause is claimed. C2 repeatedly exceeded the 64k output cap in its first thinking block. Both controls finished; three of four loop runs failed operationally, while B2 alone reached its cap. The loop improved issue discovery and some revisions, but did not reach print-ready quality, prove real seed flow, or test a physical cage.

## Clean-room audit

- **A1 — CLEAN.** The design transcript (01:16–10:19Z) contains no tool call outside A1’s directory or allowed tool environments.
- **A2 — LEAK.** At 01:49:34Z its first Bash call included `ls /home/bot/scratch/ 2>/dev/null | head -1 >/dev/null`; this touched the forbidden hopper parent even though output was discarded. No sibling design content was observed.
- **B1 — CLEAN, PROMPT-INTACT, TRUNCATED.** Its one round-1 spawn exactly matches the prompt with `__ROUND__=1` and used a new sub. It produced a round directory but returned no score before the OOM, so no revision can be credited.
- **B2 — CLEAN, PROMPT-INTACT.** Four fresh critic subs were spawned: round 1 was retried once, then rounds 2 and 3. Every prompt differs from the preserved prompt only by round and run path; durable scores were 3, 5, 5.
- **C1 — CLEAN, PROMPT-INTACT, TRUNCATED.** Round 1 was retried after interruptions, always as a fresh sub with the same intact prompt. Its durable response scored 3; the maker began but did not finish revision 1 before OOM.
- **C2 — CENSORED.** No report, source, mesh, critic spawn, or design outcome exists; six identical output-cap errors followed the initial design attempt, so it is not scored or audited as a design.

Transcript wall-clock spans were A1 9h03m, A2 10h02m, B1 14h29m, B2 17h04m, C1 17h48m, and C2 21h49m, including queue suspensions. Available transcript usage counters are not comparable per round because cache/resume accounting is incomplete; job totals were B1 1.50M, C1 1.37M, and C2 2.11M tokens. B2’s report estimates about four active hours across design, three critiques, and two revisions.
