# Difficulty Matrix

What every world mission is at every difficulty today, laid out for the 2026-11-07 difficulty pass. David's note from the headset: "Difference between difficulties still doesn't feel quite right. I think we need to do a major pass on each mission type for each difficulty." This page is the starting point for that conversation; nothing here has been changed yet. Numbers are from the wave tables and `reports/difficulty_audit.md`, not from timed runs.

## How a player meets a difficulty

The player never picks a tier. The city's state on the world map sets it (`WorldMap.tier_for`):

| City state | Card says | Tier |
|---|---|---|
| Threatened | EASY | Standard, or Assist when the world assist setting is on |
| Danger | MEDIUM | Operator |
| Overrun | HARD | Full Resonance |

Each district in a city is one of four kinds, picked at random when the city's section is generated. Shut the Maw only appears in a column with more than one district.

## The four mission kinds, as authored (Standard)

| Kind | Card name | Rifts | Total rift health | A phantom every | Most live at once | Species | Speed, tell | Ends when |
|---|---|---|---:|---|---:|---|---|---|
| Single | CLEAN SEAL | 4, one at a time | 640 | 3.4 s, then 3.0 s | 3 | all four | 1.0 then 1.06; tell 1.0 then 0.94 | all four sealed |
| Dual | CROSSFIRE | 2 pairs, both of a pair open | 1080 | 1.7 s for the first pair, 1.5 s for the second (two rifts feeding) | 4 | all four | 1.1 then 1.18; tell 0.9 then 0.82 | both pairs sealed |
| Hold | COVER THE TEAM | 1 | 2500 | 3.2 s | 3 | all four | 1.0, tell 1.0 | the team seals it in 300 s, sooner with kills |
| Maw | SHUT THE MAW | 1 huge rift, double-size phantoms | 1600 | 0.875 s | 8 | all four | 1.0, tell 1.0 | sealed; at Full Resonance, the boss |

The phantoms themselves: yellow (left hand) and blue (right hand) Anglers do 10 rift damage, 20 on a lure crit; green Carapace needs both hands, 16; pink Spearfin is dodged, 18. Punch power scales rift damage from 0.85x to 1.3x. Every phantom that reaches the player drains 20 of 100 life force before the tier's scale; life force recovers 1 a second after 3 s without a hit.

## What each tier changes

| | Assist | Standard | Operator | Full Resonance |
|---|---:|---:|---:|---:|
| Phantom speed | 0.85x | 1.0x | 1.12x | 1.0x |
| Tell length | 1.25x | 1.0x | 0.85x | 1.0x |
| Spawn interval | 1.04x | 1.0x | 0.96x | 0.5x |
| Extra phantoms live | 0 | 0 | 0 | +2 |
| Rift health | 0.96x | 1.0x | 1.04x | 1.1x, then raised to match the faster feed |
| Contact drain | 12 | 20 | 25 | 20 |
| Hits to the failsafe from full | 9 | 5 | 4 | 5 |
| Body movement | none | none | none | the Maw's boss only: squats, side-steps, jumps, push-ups |

## Every kind at every tier

Pressure per minute is the audit's one-number intensity: phantoms answered a minute, times speed, times 0.88 s over the mean tell. It leaves out contact drain and body movement.

| Kind | Tier | Card | Phantom every | Most live | Phantoms to kill | Est. minutes | Pressure/min |
|---|---|---|---|---:|---:|---:|---:|
| Clean Seal | Assist | EASY | 3.5 s, 3.1 s | 3 | 47 | 3.0 | 11.3 |
| Clean Seal | Standard | EASY | 3.4 s, 3.0 s | 3 | 49 | 3.0 | 17.3 |
| Clean Seal | Operator | MEDIUM | 3.3 s, 2.9 s | 3 | 51 | 3.0 | 23.8 |
| Clean Seal | Full Resonance | HARD | 1.7 s, 1.5 s | 5 | 86 | 3.3 | 28.0 |
| Crossfire | Assist | EASY | 1.7 s, 1.6 s | 4 | 80 | 3.1 | 23.5 |
| Crossfire | Standard | EASY | 1.7 s, 1.5 s | 4 | 83 | 3.2 | 34.7 |
| Crossfire | Operator | MEDIUM | 1.6 s, 1.4 s | 4 | 86 | 3.3 | 46.0 |
| Crossfire | Full Resonance | HARD | 0.8 s, 0.7 s | 8 | 91 | 3.4 | 35.2 |
| Cover the Team | Assist | EASY | 3.3 s | 3 | 59 | 3.4 | 11.9 |
| Cover the Team | Standard | EASY | 3.2 s | 3 | 63 | 3.5 | 18.2 |
| Cover the Team | Operator | MEDIUM | 3.1 s | 3 | 67 | 3.5 | 25.0 |
| Cover the Team | Full Resonance | HARD | 1.6 s | 5 | 111 | 3.8 | 29.2 |
| Shut the Maw | Assist | EASY | 0.9 s | 8 | 118 | 4.0 | 19.9 |
| Shut the Maw | Standard | EASY | 0.9 s | 8 | 123 | 4.2 | 29.3 |
| Shut the Maw | Operator | MEDIUM | 0.8 s | 8 | 128 | 4.4 | 38.6 |
| Shut the Maw | Full Resonance | HARD | 0.4 s, then the boss | 10 | 97 and the boss | 4.5 | 21.2 |

A phantom cannot be answered faster than the player can kill, about one every 2 s in the model. Wherever the feed is faster than that, as on Crossfire and the Maw at every tier, the extra phantoms do not add kills; they fill the live cap and wait.

## What the layout shows

1. **The mission kind moves difficulty more than the tier does.** An EASY Crossfire (34.7) is harder on paper than a MEDIUM Clean Seal (23.8) and a HARD Clean Seal (28.0). An EASY Maw (29.3) matches a HARD Cover the Team (29.2). The card's EASY, MEDIUM, HARD only holds within one kind.
2. **Standard and Operator are the same fight, slightly quicker.** Same phantoms, same count, same feed within 4 %, same live cap. Operator is 12 % faster with 15 % shorter tells and 25 % more drain. A 12 % speed change is hard to feel in a headset; the drain only shows when you get hit.
3. **Assist and Standard differ mostly in forgiveness.** Nine hits to the failsafe instead of five, with slower phantoms and longer tells. Same length, same count.
4. **Full Resonance is not the top tier everywhere.** It keeps Standard's speed and tells, so where the player's own pace already set the tempo it adds little: Crossfire at Full Resonance (35.2) sits below Operator (46.0), and the Maw at Full Resonance (21.2) reads below Standard (29.3) because half its time is the boss's tentacles, which the figure does not count. On Clean Seal and Cover the Team it is the hardest, through numbers alone.
5. **Full Resonance asks for the body on one kind of four.** Squats, jumps, side-steps, and push-ups come only from the Maw's boss. Clean Seal, Crossfire, and Cover the Team at HARD are the same movements as EASY with more phantoms. The overrun card promises "squats, jumps, side-steps, and push-ups" on every district.
6. **Every district runs three to four and a half minutes.** All under the roadmap's five-minute floor, and the tiers barely change it, by design since 2026-11-01 (Assist and Operator within 5 % of Standard, Full Resonance about 10 % longer).
7. **The pink just got easier to read wrong.** With the floor lane gone (2026-11-07), a pink is answered from its bill and aim alone. Expect more pink hits at every tier until players learn it; Operator's shorter tells cut its 1.15 s tell to under a second.

## Questions for the pass

- What should a step up in tier feel like: more phantoms at once, faster ones, less forgiveness, or new things to do with the body? Today each tier leans on one or two of these, and differently per kind.
- Should EASY, MEDIUM, and HARD mean the same intensity whatever the kind, so the kind changes the shape of the fight but not how hard it is?
- Should HARD bring movement to every kind, not only the Maw? Known Issues item 10 has the one candidate with a source in the fiction: a short tentacle lash from the rift.
- Should tiers stay the same length, or may a harder tier run longer?
