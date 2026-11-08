# Difficulty Tuning

How mission difficulty is kept consistent across the world's three difficulty levels and their missions, and how real runs on the headset feed back into the numbers. Built 2026-11-01; reworked 2026-11-08 when each level got its own missions ([Difficulty_Matrix.md](Difficulty_Matrix.md)). David's words: "We do need to do some work around difficulty of missions to make sure they consistently match."

There are two halves. The audit compares every mission on paper and fails validation when they drift apart. The run log records what a round actually took, so the paper numbers can be replaced.

## The audit (on paper)

`Tests/difficulty_audit.gd` reads every world mission at the level it is played: each level's roster (`WorldMap.ROSTERS`) at its tier, both forms of Close the Sector, and the Easy missions at Assist too. The validation runner calls it on every run and writes [reports/difficulty_audit.md](../reports/difficulty_audit.md), which is committed so a retune shows up as a diff. The report's header explains every column. The six Breach Night operations are debug-only and no longer audited.

Each row carries the rift health, the phantoms a clean run kills, the feed's spawn interval and live cap, the pinks, Rays, and Eels a minute from the extras layer, the mean tell and speed, the estimated minutes, the card, and one pressure-per-minute figure. Pressure per minute is phantoms and extras answered a minute while the feed runs, times speed, times 0.88 s over the mean tell. Contact damage and the boss's own attacks are not in it.

The estimate is `WorldMap.run_seconds`. It assumes 13 rift damage per kill at average punch power, one kill per spawn interval but never faster than one every 2 s, the extras' own rift damage on top (each extra answered once in its interval), and 6 s per rift opening. A hold's own drain adds to the player's. A boss row runs phase one on its share of the rift's health, the 13.5 s turn, and the anchor draining on its own plus one resolve's work every 4 s.

Validation fails when any of these breaks. The design behind them is David's, from 2026-11-08 ([Difficulty_Matrix.md](Difficulty_Matrix.md)):

1. **The estimate is on the card.** For the full Maw, both a Maw that breaks and one that holds.
2. **Every mission runs inside its level's minutes:** Easy 3 to 4.5, Medium 4.5 to 6.5, Hard 4.5 to 7.5. Harder levels may run longer.
3. **Intensity rises at every level whatever the mission.** Each level's least intense mission must be more pressure than the level below's most intense.
4. **Assist runs within 5 % of Standard and is gentler.**
5. **The species rules.** Every feed is yellow, blue, and green only, with green less frequent than either; Eels only at Hard; no Rays or Eels at Easy; a Ray asks a duck below Hard and a squat at it; every Hard mission except the boss arc asks for both a squat (Rays) and a jump (Eels).

### History

The first audit (2026-11-01) compared districts with their sibling operations and held every tier to a mission's length: Assist and Operator within 5 % of Standard, Full Resonance 10 % longer. It found the tiers moved paired missions and The Maw by 12 to 20 % and retuned them. On 2026-11-07 David found the levels still did not feel distinct, and the layout showed why: the mission kind moved pressure more than the tier, Operator was Standard 12 % faster, and Full Resonance only moved the body in the Maw. The 2026-11-08 pass replaced tier multipliers with missions authored per level, and the audit with the checks above.

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
4. Read the second table: Assist's median against Standard's for the same mission, which should be within a few percent. The other levels play their own missions, so compare them by the first table's cards and against each other (Medium longer and harder than Easy, Hard than Medium).

Defeats are counted but never timed: a defeat ends when life force runs out, which says nothing about how long a seal takes.

## Turning the numbers into changes

Wait for at least three victories of a mission at a tier before changing anything for it. One run is noise.

**Recalibrate the estimator first.** The audit's whole model rests on two constants in `Scripts/Core/world_map.gd`: `KILL_DAMAGE` (13) and `KILL_CADENCE_SECONDS` (2.0). `Dmg/kill` from the log is the real damage per kill for whoever played. `KILL_DAMAGE` is the average puncher's, and the card's low end assumes 1.3 times it. So if the log comes from one hard puncher, set `KILL_DAMAGE` to about `Dmg/kill` divided by 1.3; if it pools many testers, use `Dmg/kill` as it is. `s/kill` on paired missions and The Maw, where the feed outruns the player, is the real cadence. Change the two constants, run validation, and read the regenerated report: every card the real numbers disagree with now fails the "on the card" check. Fixing the model first fixes every card, district, and tier estimate at once, including missions nobody timed.

**Then the cards.** District cards come from the formula in `WorldMap.build_mission`, so they follow the constants. Where a mission is still flagged, a card can be set by hand in `build_mission` so the low end is about the fastest typical victory and the high end the slowest; validation only requires it to contain the estimate.

**Then the missions.** Each mission is authored at its level in `WorldMap.build_mission`, so a mission that runs long or short, or feels too easy or hard for its level, is changed there:

- Too short or too long: change its rifts' health. Slowing the feed only adds waiting.
- The right length but too easy or too hard: change the feed (`interval`, `max_live`), the extras (`every`), or the level's pace (`LEVEL_PACE`: speed and tells). Each changes the challenge more than the time.
- Assist off Standard by more than 5 %: change Assist's `health` and `interval` in `Scripts/Core/difficulty_tier.gd` together.

The audit then says whether the levels still step up and every mission still sits in its level's minutes.

After any change, run validation. The report regenerates; commit it with the change, so the diff shows the before and after. Note the session and the change in [Playtest_Log.md](Playtest_Log.md).
