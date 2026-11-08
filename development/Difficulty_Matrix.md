# Difficulty Matrix

The design of the three difficulty levels and the missions each one plays, built 2026-11-08. The first version of this page (2026-11-07) laid out what the game had then. David confirmed it matched what he felt: the mission kind moved difficulty more than the tier, Medium played like Easy slightly faster, and Hard only moved the body in the Maw. The design below is what he chose in answer. `Tests/difficulty_audit.gd` holds it on every validation run and writes the numbers to [reports/difficulty_audit.md](../reports/difficulty_audit.md).

## What David decided

- **A step up is more phantoms, a bit faster, and new body movements.** Forgiveness stays the same: every contact drains 20 at every level. Assist is still the separate accessibility setting for threatened cities.
- **Easy is clearly gentler, and intensity rises at every level whatever the mission.** Every Medium mission is more pressure than every Easy one, and every Hard one more than every Medium one.
- **Harder levels may run longer.** Easy about three and a half minutes, Medium five to six, Hard five to seven.
- **Each level has its own missions.** Some cross levels and scale by speed and feed; others belong to one level. The third district of every section is the level's finale.
- **Species rules.** Yellow and blue are always the most frequent and green always the least. Pinks appear more on Medium and Hard, as an extra layer on top of the normal feed, so the Striker dodges and punches close together.
- **Movement comes from phantoms, not the rift.** The rift attacking (blades, slams) felt wrong to David. Two new species carry the movements: the Ray (go under it) and the Eel (jump it). Push-ups stay with the Maw's tentacles, because getting down for a quick push-up in VR is awkward. The Flatfish push-up phantom was considered and rejected.
- **Every Hard mission asks for squats and jumps.** David was unsure but wants to try it; a player who finds it too much can play a city in danger instead.
- **Per-district twists are on hold** until the missions themselves are balanced ([Ideas_Backlog.md](Ideas_Backlog.md)).

## The levels

| | EASY (threatened city) | MEDIUM (city in danger) | HARD (overrun city) |
|---|---|---|---|
| Tier | Standard, or Assist | Operator | Full Resonance |
| Phantom speed, tell | 0.92x, 1.12x | 1.1x, 0.9x | 1.2x, 0.85x |
| A phantom every | about 3 s | about 1.6 to 2.2 s | about 0.7 to 2.5 s, with more extras where the feed is slower |
| Most live (the feed) | 3 | 4 to 6 | 4 to 10 |
| Pinks (extras) | only in the finale | every 10 to 16 s | every 3 to 15 s |
| Rays | none | duck height, in Low Ceiling and the finale | squat height, in every mission |
| Eels | none | none | in every mission |
| Boss | none | the Maw's lighter form, sometimes, in the finale | the full Maw in the finale |
| Chen's countdown line | none | `deploy_medium` | `deploy_hard_moves` |
| Minutes (average puncher, clean) | 3.4 to 3.8 | 4.8 to 6.2 | 5.1 to 6.5 |

`DifficultyTier` no longer scales speed, tells, health, or the feed at Standard, Operator, or Full Resonance: each mission is authored at its level's pace in `WorldMap.build_mission`. A tier now sets what the level asks of the body (a duck at most below Full Resonance, squats and jumps at it), drops an Eel from any wave below Full Resonance, lets the lighter boss through at Operator and the full one at Full Resonance, and picks Chen's countdown line. Assist still scales: slower, longer tells, softer contact, at about Standard's length.

## The missions

| Level | Mission | Kind id | What it is |
|---|---|---|---|
| Easy | **Clean Seal** | `single` | Four rifts in turn, each a little faster. Punching only. |
| Easy | **Cover the Team** | `hold` | One rift the team seals in five minutes; kills shorten it. |
| Easy finale | **First Charge** | `first_charge` | Four rifts with pinks joining in, one about every nine seconds. |
| Medium | **Flurry** | `flurry` | Three rifts of a fast, steady yellow and blue stream; a pink every twelve seconds. |
| Medium | **Crossfire** | `dual` | Two pairs of rifts in one view, pinks between them. |
| Medium | **Low Ceiling** | `low_ceiling` | Four rifts with a Ray every eleven seconds to duck under, and pinks. |
| Medium finale | **Close the Sector** | `close_sector` | In about three sections of five, a harder Crossfire with pinks and Rays; in the other two, the Maw's lighter form. The card never says which. |
| Hard | **Flurry** | `flurry` | The same mission at Hard: a phantom about every 1.25 s, two pinks at once, Rays and Eels. |
| Hard | **Storm** | `storm` | A slower feed under a pink every three seconds, a Ray every ten, an Eel every twelve. Dodging everywhere. |
| Hard | **Undertow** | `undertow` | A fast feed with Rays, Eels, and pinks mixed in. |
| Hard | **Last Stand** | `last_stand` | Three hold rifts open across the front at -60, 0, and 60 degrees; the team seals them while the Striker holds. A front arc first, not a full circle. |
| Hard finale | **Shut the Maw** | `maw` | The Maw's flood with pinks, Rays, and Eels, then the full boss when it breaks. |

A section's first two columns deal the level's regular missions from a shuffled bag, seeded by city, section, and level, so a section mixes them and a card never changes under the player. The last column is one district: the finale. A city that changes level (its front recedes) keeps its layout and deals the new level's missions.

## The extras layer

Pinks, Rays, and Eels come from a wave's `extras`, each on its own timer, and never take one of the feed's `max_live` slots (`RiftManager`). That keeps yellow and blue the steady stream. A pink waits until a phantom of the feed is out, so the dodge lands between punches. Rays and Eels are sweeps under the skin (`SweepCreature`): they fly out of the rift, line up, and are judged exactly as the sweep's blade, but nothing of the rift is drawn. Like every sweep they wait for one another, so ducks and jumps never come back to back.

## The Maw's lighter form

Close the Sector's boss form at Medium (`"light": true` on its boss block, `MawBoss.is_light`): duck-depth sweeps, a slam that pulls straight back with no spent tentacle, no jump pair, and no push-ups. It always comes through when the section deals it and leaves the Full Resonance break odds alone. Chen opens it with `boss_medium_ready` and calls the slam's withdrawal with `boss_slam_withdraw`.

## What the audit holds

- Every mission's estimate is on its card.
- Every mission runs inside its level's minutes: Easy 3 to 4.5, Medium 4.5 to 6.5, Hard 4.5 to 7.5.
- Each level's least intense mission is more pressure than the level below's most intense. On paper today Easy runs 10 to 26, Medium 44 to 56, Hard 62 to 82.
- Assist runs within 5 % of Standard and is gentler.
- Every wave's feed is yellow, blue, and green only, with green less frequent than either; Eels only at Hard; Rays and Eels never at Easy; a Ray asks a duck below Hard and a squat at it; every Hard mission but the boss arc has both Rays and Eels.

## Open questions

- **Untested on the headset.** Every number here is the paper model. The run log will show real lengths per mission and level.
- **The Ray's look.** Its nose lifts so the Striker sees its belly, not a thin edge; whether that reads at speed needs the headset.
- **Close the Sector's card is wide** (3 to 9 minutes) because it covers both forms without saying which.
- **Every Hard mission moves the body.** If that proves too much, the first lever is fewer Eels outside Storm and Undertow.
