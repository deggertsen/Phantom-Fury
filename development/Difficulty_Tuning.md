# Difficulty Tuning

How mission difficulty is kept consistent across Breach Night operations, world districts, and the four tiers, and how real runs on the headset feed back into the numbers. Built 2026-11-01. David's words: "We do need to do some work around difficulty of missions to make sure they consistently match."

There are two halves. The audit compares every mission on paper and fails validation when they drift apart. The run log records what a round actually took, so the paper numbers can be replaced.

## The audit (on paper)

`Tests/difficulty_audit.gd` reads the wave tables of the six operations and the four district kinds at all four tiers. The validation runner calls it on every run and writes [reports/difficulty_audit.md](../reports/difficulty_audit.md), which is committed so a retune shows up as a diff. The report's header explains every column.

Each row carries the rift health, the phantoms a clean run kills, the peak live phantoms, the spawn feed, the mean tell, the mean speed, the estimated minutes, the card, and one pressure-per-minute figure. Pressure per minute is phantoms answered a minute, times speed, times 0.88 s over the mean tell. More phantoms, faster ones, and shorter tells all raise it. Contact damage is not in it.

The estimate is `WorldMap.run_seconds`. It assumes 13 rift damage per kill at average punch power, one kill per spawn interval but never faster than one every 2 s, and 6 s per rift opening. Pairs are capped by that cadence. A hold's own drain adds to the player's. The Maw at Full Resonance runs as phase one on half its health, the 13.5 s turn, and the anchor draining on its own plus one resolve's work every 4 s.

Validation fails when any of these breaks:

1. **The estimate is on the card.** At every tier, the average puncher's clean run, rounded to a whole minute, sits inside the range the card shows. For The Maw at Full Resonance, both a Maw that breaks and one that holds.
2. **Tiers keep a mission's length.** Assist and Operator run within 5 % of Standard. Full Resonance runs 10 % longer, give or take 5 %. Tiers change how hard a mission is, not how long. Since 2026-11-01 Full Resonance is a pace tier as well as the movement tier: the feed runs at half the interval (a phantom every second or two, David's ask from the headset), two more phantoms may be live, and rift health is 1.1x and then, per group of rifts open together, as much more as the faster feed lets the player kill faster (`DifficultyTier._scale_health_with_pace`: the group's spawns a second, capped at the player's cadence, at the tier over the same at Standard). Where the player's cadence already set the pace, as on pairs and The Maw, the feed changes nothing and health stays 1.1x. So the length still lands about 10 % over Standard everywhere.
3. **Districts weigh what their sibling operation weighs.** A district kind's pressure per minute stays within 15 % of its sibling's at the same tier. The siblings:

| District kind | Sibling operation | Why |
|---|---|---|
| Clean Seal | Widen the Ring | Four species at a 3 to 4 s feed, one rift at a time |
| Crossfire | Double Breach | Pairs of rifts in one view |
| Cover the Team | Widen the Ring | One rift of all four species at Standard speed and tells |
| Shut the Maw | The Maw | The Maw's own rift |

Districts are shorter than operations by design (four rifts, or one hold), so length is reported against the sibling but not held to a band. The report also lists, without failing, every mission from OP-02 on that runs under the roadmap's five-minute floor on paper.

### What the first audit found, and the retune

The first audit (2026-11-01) found the cards and the district kinds consistent, and the tiers not.

- **Tier lengths.** Where the player's own kill cadence sets the pace (pairs, The Maw), only rift health changes the length; the spawn interval cannot offset it. Assist's 0.8 health made Double Breach, Open Arc, and Crossfire 15 to 17 % shorter and The Maw 20 % shorter. Operator's 1.15 made them 12 to 15 % longer. Assist's Maw estimate fell off its card. The fix keeps health and interval near 1 for both: Assist 0.96 health and 1.04 interval, Operator 1.04 and 0.96. Speed, tells, and contact, which are what the two tiers are about, are unchanged.
- **Cover the Team at Full Resonance** ran only 3 % longer, because the team's seal took 300 s at every tier. A hold's `hold_seconds` now scales with the tier's health, so the drain keeps Standard's pace.
- **Cards.** The old low ends were the average puncher's clean run, and the developer finished under them on 2026-10-24. Punch power (2026-10-13) is the likely reason: a hard punch does 1.3x rift damage. A card is now `WorldMap.expected_minutes`: a hard puncher's clean run to an average one with half again for misses. First Light 2 to 3, Widen the Ring 5 to 9, Chen's Gambit 5 to 8, The Maw 3 to 6. Double Breach and Open Arc stay 6 to 10, and the Full Resonance Maw stays 4 to 7. Districts take the same formula: Clean Seal 2 to 4, Crossfire 3 to 5, Cover the Team 3 to 4.

No phantom behavior changed.

## The run log (real runs)

Every finished round appends one line to `user://run_log.csv` (`Scripts/Core/run_log.gd`, owned by `RoundController`). It is on in every build, debug and release. Abandoned rounds and training write nothing. On Android the game also keeps a copy at `Android/data/com.phantomfury.resonancerising/files/run_log.csv`, which `adb pull` can read on a release build.

| Column | What it is |
|---|---|
| `date` | Local date and time the round finished |
| `mission_id` | The operation id, or `world:<city>:<section>:<district>` |
| `kind` | `operation`, or the district kind (`single`, `dual`, `hold`, `maw`) |
| `tier` | `assist`, `standard`, `operator`, `full_resonance` |
| `outcome` | `victory` or `defeat` |
| `elapsed_seconds` | The mission clock: live play, pauses excluded |
| `score` | Final score |
| `phantoms_resolved` | Resolves of every kind: strikes, blocks, dodges, and work on a boss |
| `misses` | Contacts that reached the player |
| `rejections` | Strikes refused (wrong hand) |
| `rifts_sealed`, `rifts_total` | Rifts sealed, out of the mission's |
| `rift_health` | Total rift health at that tier, for damage per kill |
| `expected_min`, `expected_max` | The card's range at that tier, as shown |
| `boss` | `breaks` or `holds` for The Maw at Full Resonance, otherwise empty |
| `version_code` | The Android version code, from `application/config/version_code` in `project.godot` |

The file stays on the headset. Nothing is sent anywhere, and it holds no account, name, or device identifier ([Privacy_Policy.md](Privacy_Policy.md)). `tools/deploy_quest.ps1` bumps `config/version_code` with the export presets, and validation fails if they disagree.

## After a headset session

1. Plug the Quest in, put it on, and accept USB debugging if asked.
2. Run:

   ```bash
   powershell -ExecutionPolicy Bypass -File tools/pull_run_log.ps1
   ```

   It reads the private file with `run-as` on a debug build. A release build refuses `run-as`, so it falls back to the copy in `Android/data/<package>/files`. Force one with `-Source private` or `-Source external`. The file is saved under `reports/run_log/`. To read a file you already have, pass `-CsvPath <file>`; `-SinceVersion <code>` drops rounds from older builds, whose cards may differ.
3. Read the first table. One row per mission and tier: victories, defeats, median, fastest and slowest victory in minutes, the card, and a flag when the median, rounded, is under or over the card. Districts group by kind (`world:single` and so on). `Dmg/kill` and `s/kill` are the median rift health per resolve and seconds per resolve.
4. Read the second table: each tier's median against Standard's for the same mission, with the target (0 % for Assist and Operator, +10 % for Full Resonance).

Defeats are counted but never timed: a defeat ends when life force runs out, which says nothing about how long a seal takes.

## Turning the numbers into changes

Wait for at least three victories of a mission at a tier before changing anything for it. One run is noise.

**Recalibrate the estimator first.** The audit's whole model rests on two constants in `Scripts/Core/world_map.gd`: `KILL_DAMAGE` (13) and `KILL_CADENCE_SECONDS` (2.0). `Dmg/kill` from the log is the real damage per kill for whoever played. `KILL_DAMAGE` is the average puncher's, and the card's low end assumes 1.3 times it. So if the log comes from one hard puncher, set `KILL_DAMAGE` to about `Dmg/kill` divided by 1.3; if it pools many testers, use `Dmg/kill` as it is. `s/kill` on paired missions and The Maw, where the feed outruns the player, is the real cadence. Change the two constants, run validation, and read the regenerated report: every card the real numbers disagree with now fails the "on the card" check. Fixing the model first fixes every card, district, and tier estimate at once, including missions nobody timed.

**Then the cards.** Where a mission is flagged after recalibration, set its `expected_minutes` in `Scripts/Core/mission_catalog.gd` so the low end is about the fastest typical victory and the high end the slowest. Keep the median inside. District cards come from the formula in `WorldMap.build_mission`, so they follow the constants. A card set by hand from data no longer matches the formula; validation only requires it to contain the estimate.

**Then the tiers.** If Assist or Operator runs more than 5 % off Standard, or Full Resonance is not about 10 % longer:

- On paired missions and The Maw, change the tier's `health` multiplier in `Scripts/Core/difficulty_tier.gd`. The player's cadence sets the pace there.
- On single-rift missions, the feed sets the pace, so `health` times `interval` is the length. Keep the two together.
- If a tier is too hard or too easy but the right length, change `speed`, `telegraph`, or `contact` instead. Those change the challenge, not the time.

**Then mission lengths.** If a mission is consistently under the roadmap's 5 to 10 minutes from OP-02 on, raise its rift health (or add rifts) rather than slowing the feed, which only adds waiting. OP-01 stays short.

After any change, run validation. The report regenerates; commit it with the change, so the diff shows the before and after. Note the session and the change in [Playtest_Log.md](Playtest_Log.md).
