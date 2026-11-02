# Session Stats and Medals

**Built:** 2026-11-01, Roadmap Phase 6.
**Code:** `Scripts/Core/session_stats.gd` (`SessionStats`), `Scripts/Core/mission_medals.gd` (`MissionMedals`), `Scripts/UI/medal_badge.gd` (`MedalBadge`). Validation: `_validate_session_stats`, `_validate_medals`, `_validate_workout_results` in `Tests/validation_runner.gd`.

Fitness is the product, so the results screens show the workout, and every mission card shows the best score and the medal it earned.

## Session stats

`RoundController` owns a `SessionStats` and resets it on every deploy. It counts only what already flows through the round, and only while the round is live (no countdown, no pause):

| Stat | Source |
|---|---|
| Punches thrown | every strike a glove delivers to a phantom, landed or rejected (`CombatHandController` calls `RoundController.record_strike` with `Phantom.receive_strike`'s result). A swing that meets nothing is not counted. A green block is two punches. |
| Rejected, and wrong hand | strikes whose result is not valid; `wrong_hand` counted on its own |
| Resolves by phantom and kind | `RiftDirector.phantom_resolved`: gold (yellow) and blue Anglers punched, green two-hand blocks, pink and slam dodges |
| Lure crits | resolves with `sweet_spot` |
| Missed | `RiftDirector.player_damaged`: a phantom or hazard that reached the Striker |
| Longest chain | the highest `sweet_streak` the round reached (the HUD's chain) |
| Rifts sealed | `RiftDirector.rift_closed` while live |
| Active time | `elapsed_seconds`, the round's live clock |
| Calories (estimate) | below |

Results show them on the left panel, under the outcome: six numbers (punches, lure crits, best chain, active time, kcal, rifts sealed), then two lines of gold, blue, blocks, dodges, missed, and wrong hand. Stats show after a defeat too: the workout still happened. Nothing is saved.

## Calorie estimate

```
kcal = active minutes × MET × 3.5 × 75 kg / 200
MET  = lerp(6.1, 7.6, clamp(punches per active minute / 30, 0, 1))
```

- Standing boxing-type exertion is about 6 to 8 METs (Compendium of Physical Activities: boxing, punching bag 5.5; sparring 7.8).
- `MET × 3.5 × kg / 200` is the standard kcal-per-minute conversion. At an assumed 75 kg Striker, 6.1 METs is 8.0 kcal a minute and 7.6 METs is 10.0.
- The punch rate nudges the rate inside that band: a round with almost no punching sits at 8.0 kcal a minute, 30 punches a minute or more at 10.0.
- Active minutes are the round's live clock. The countdown and pause never count.

It is labeled `KCAL (EST.)` on screen with a `~` in front. Tune it in `SessionStats` (`BODY_KG`, `MET_FLOOR`, `MET_CEILING`, `PUNCH_RATE_CEILING`). A body-mass setting would replace the 75 kg assumption; squats, jumps, and push-ups at Full Resonance are not yet counted toward the rate.

## Best score

`GameSettings.record_score` already kept a best score per mission and tier (world records per city, district kind, and tier under `"world:<city>:<kind>"`). It now shows:

- Results, left panel: YOUR BEST at the tier played, the time and the score side by side with the best medal.
- Results, center header: NEW BEST SCORE under the score when it beats a stored best, exactly as NEW BEST TIME works (`previous_best_score` is the best before the round; a first clear has nothing to beat). Otherwise the line names the round's medal: `SILVER • SCORE`.
- The Breach Night site card: `BEST SCORE` with the medal, under the expected time and YOUR BEST.
- The district card: a BEST SCORE row under YOUR BEST, with the medal.
- Sealed sites on the Breach Night map: `BEST 1:34 • 5,618` and the medal pinned to the marker.

Chen's "new record" line now reads the world record for world missions too (it was reading the district's mission id, which never has a record).

## Medals

Bronze, silver, and gold for a victory, from the score, measured against each mission's own **par** at the tier played. Tiers change the waves (health, spawn interval), so they change par: medals are per tier, as scores are.

**Par** is the score of a reference round on the mission's waves (`MissionMedals.reference_score`):

- every phantom resolved cleanly, in the wave's pool order, each gold and blue Angler on its lure;
- the chain held through each rift (and restarted at each new rift), except where the rift feeds slower than the 4 s combo timeout, where every kill starts a new chain;
- one kill per spawn interval, never faster than one every 2 s (`WorldMap.KILL_CADENCE_SECONDS`);
- a firm punch, 1.15 times a phantom's rift damage (`REFERENCE_POWER`, about 4.7 m/s);
- Cover the Team's rift also drains on the team's clock, so fewer kills are needed;
- score per resolve as `RoundController` awards it: base points × the multiplier, which gains 0.15 a resolve, 0.2 more for a crit, 0.1 more on the beat (pinks), up to 3.0.

**Thresholds** (`MissionMedals.thresholds`):

| Medal | Score |
|---|---|
| Bronze | any victory (a best score exists only for a victory) |
| Silver | 70% of par: a clean run without crits gets there; a run that breaks the chain every few resolves does not |
| Gold | par: it takes lure crits and long chains |

The best medal is the medal of the best score, so it needs no storage of its own.

### Numbers at Standard

| Mission | Silver | Gold (par) | Clean, no crits | Chain broken every 3, no crits |
|---|---|---|---|---|
| First Light | 3,765 | 5,378 | 4,060 (silver) | 3,430 (bronze) |
| Widen the Ring | 19,110 | 27,300 | 22,200 | 16,880 |
| Chen's Gambit | 19,973 | 28,532 | 25,164 | 18,528 |
| Double Breach, Open Arc | 29,375 | 41,964 | 37,060 | 27,064 |
| The Maw, Shut the Maw | 31,104 | 44,434 | 43,156 | 20,074 |
| Clean Seal | 10,008 | 14,296 | 12,036 (silver) | 8,010 (bronze) |
| Crossfire | 19,119 | 27,312 | 24,400 | 13,736 |
| Cover the Team | 21,444 | 30,634 | 24,616 | 11,760 |

First Light and Clean Seal at every tier (silver / gold):

| | Assist | Standard | Operator | Full Resonance |
|---|---|---|---|---|
| First Light | 3,387 / 4,838 | 3,765 / 5,378 | 5,143 / 7,346 | 4,535 / 6,478 |
| Clean Seal | 7,584 / 10,834 | 10,008 / 14,296 | 12,528 / 17,896 | 10,932 / 15,616 |

Tune `SILVER_SHARE`, `GOLD_SHARE`, and `REFERENCE_POWER` in `MissionMedals`. Its `VARIANTS` table copies each phantom's points and damage; validation fails if a phantom changes and the table does not.

### Glyph

`MedalBadge` draws the medal: two blue ribbon tails over a disc in gold (`#ffd04a`), silver (`#d6e2f2`), or bronze (`#d98a4f`), with a dark ring inside. The three differ in brightness as well as hue, and every place but the map marker also writes the name in the medal's color.

## Known limits, for tuning

- **A harder punch scores less over a mission.** Each phantom scores the same however hard it is hit, but a harder punch (or a crit, which does double rift damage) closes the rift in fewer phantoms. A soft, crit-less player who keeps the chain can out-score a hard-hitting one, and medals inherit that: a clean no-crit run at a soft punch (0.9) reaches par or more on most missions. Not changed on this pass (no phantom or scoring changes); a fix would weight score by rift damage or give crits points without the extra rift damage.
- **First Light's first rift feeds every 4.2 s, past the 4 s combo timeout**, so its chain only holds when kills bunch up. At Assist, where every interval is 15% longer, most waves feed slower than the timeout, chains matter less there, and a chain-breaking run can still reach silver on some missions.
- **The Maw at Full Resonance** can break into the boss fight; par counts only phase one's waves, so the boss phase's points make gold easier there.
- Par is a model, not a timed run. Replace the shares with numbers from headset runs once testers report scores.
