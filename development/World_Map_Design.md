# World Map Design

**Decided:** 2026-10-25, from the interactive mock-up (Phantom Fury World Map artifact, version 8) and David's answers.
**Status:** In build on `claude/world-map`. This document is the spec the code follows; where the code and this text disagree, fix one and say which.

## The idea in one paragraph

Strikers fight a war with a direction. The Breach opened at Jakarta on day zero and a Second Tear opened at Chicago on day 31. Everything behind those fronts is consumed. Every city's state comes from its distance to the nearest front, and the state decides what missions it offers and how hard they are. Picking a city zooms into one section of it: a handful of districts joined into a short path. Three missions along a connected path make an operation, which pushes the line back and moves the city's liberation bar. New ground opens behind it, and a Striker can keep going until the city is liberated. Nothing is ever permanently lost.

## City states

State is computed, never assigned. In projected map units (`WorldMap.project`, 1000 by 560, equirectangular with latitude cropped to [-58, 84]):

| State | Rule | Missions | Tier | Shown |
|---|---|---|---|---|
| Consumed | inside a front polygon | none, out of reach | none | hatched, dim marker |
| Overrun | within 16 units of a front | hard, with bosses | Full Resonance | magenta |
| In danger | within 42 units | medium, hold the line | Operator | amber |
| Threatened | within 80 units | easy | Standard, or Assist as the session choice | cyan |
| Safe | farther | none, no threat detected | none | small dim dot |

Cities far from a front are not under attack, which is what fixes "random cities around the world." When the fronts move, the states follow.

The difficulty buttons leave the Operations screen. The city's state is the tier. The one choice left to the player inside a threatened city is Assist against Standard, offered as a session toggle that changes the body's load and never the city.

## Fronts

Two polygons in longitude and latitude (`WorldMap.ZONES`), one around the Jakarta tear covering South and Southeast Asia and Australia, one around the Chicago tear covering the Midwest to the East Coast and the Gulf. They are the war as a fresh profile finds it: the seeded operations are already in these shapes.

**The fronts never advance until the war has a heartbeat.** The long-term plan is a server, with an AI or an admin moving the phantoms over time and narrating it; until then nothing pushes outward, and alpha testers can fight the phantoms all the way back (David, 2026-11-01). What does move is the player's own push: each completed operation in a front's cities shrinks that front toward its tear by its share (`WorldMap.recession`: the player's completed operations over the operations those cities still took when the profile began, with the tear's own city left out). At full recession the authored shape has shrunk by `RECESSION_MAX` (88 percent) about the tear. A city's front is the nearest authored polygon (`zone_of`). As a front recedes, consumed cities behind it come out as overrun and open up, so the war is fought inward: the coast first, the tear last. When every other city of a front is liberated, the tear's city itself turns overrun, the last fight of that front, and liberating it removes the front entirely (`zone_polygons(settings)`). The drawn map shows these receded fronts; the footer says why they move.

## Liberation

Each city has a resistance: the number of operations it takes to liberate it (`ops`). Liberation is operations completed over operations needed. The bar moves only when an operation completes, so a single mission cannot be farmed for war progress; the operation in progress shows as a dashed segment. Rift counts are never shown: a mission opens and closes many rifts, so a count would lie.

World liberation on the header is the mean of city liberation, with safe cities at 100 and consumed at 0.

A city with every operation done is **liberated**: it shows LIBERATED with a cyan ring on the map, has no missions, and counts 100 whatever the front near it is doing (`city_entries`). It will get missions again only when the war can push a front back over it.

## City view: one section at a time

A section is a small directed graph in three columns, generated from a seed of city id and section index so it is stable for that city until it is completed:

- Each column has one to three districts; every district links forward to at least one in the next column.
- District kinds: Clean Seal, Crossfire, Cover the Team, Shut the Maw (see below). A column with one district is never a Maw, and a column is never all Maws, so a path around a Maw always exists.
- District names come from a fixed pool (Harbor, Rail Yards, Junction, Stadium, Reservoir, Old Town, Civic Ring, Foundry, Airport, Docks, University, Bluffs, Quarry, Northgate, Eastbank, Riverside). A district's site id is its name as a key (`rail_yards`), passed straight to `ArenaPresentation.apply_site` before the deploy; `BreachSites.DISTRICTS` says which of the seven sites each plays at (harbor, docks, reservoir and riverside at the harbor; stadium; old town and university in the small town; the airport on the salt flat; bluffs and quarry on the summit; the rest in the Dead City), and anything unknown plays in the Dead City. Validation checks every district name has an entry.
- The player picks any district in the first column, then any linked district, then any linked district. Three seals complete the operation. The front line across the city map sits one column right of the last sealed district.
- On completion the section is replaced by the next one and the city's `ops_done` increments. The player can continue or leave. A liberated city has no sections; Chen says she will call when the front turns back toward it.
- Sections are not labeled or numbered on screen.
- The world map gets there in two steps. The whole world shows six regions, one per continent (North America, South America, Europe, Africa, Asia, Oceania; `WorldMap.REGIONS`) as the pickable outlines, each with its name and how many of its cities are in reach. Each region is an authored box in longitude and latitude, not one grown from its cities, so no box crosses into another continent (David, 2026-10-26: Asia was taking part of Australia and Oceania was only Australia): Asia stops at Australia's north coast, Europe and Africa split along the Mediterranean, both meet Asia at 45° east, and Oceania covers Australia and New Zealand though only Perth and Sydney are cities. Boxes may share an edge but never overlap, every city is in exactly one and inside its box, and validation checks all of it; the cities stay drawn so the fronts read. Picking a region eases the map to it (0.5 s) and its cities become the buttons; Whole World eases back. Open on the city card closes the map in on the city (0.45 s), and only then does the section take the panels. The way back from a section starts on the city and eases out to its region, which `GameFlowController` remembers; the World Map button on the main menu starts at the whole world.
- A mission's results are the city map (David, 2026-10-26: results looked like the map but could not deploy). The center keeps the outcome, time and score over the section as it now stands, with the new line drawn against the old one after a seal; its open districts press like the city map's, and the right panel is the picked district's card with Deploy. After a seal the next open district is picked; after a completed operation the next section shows, its first column open, under OPERATION COMPLETE; after a defeat Retry leads until another district is picked. The left panel keeps the liberation number and THE LINE MOVED, OPERATION COMPLETE, THE LINE HELD (a replay of a sealed district: its time counts, nothing moves) or THE BREACH HELD, with Replay, World and Settings under it.

## Missions from districts

A district's kind, the city's tier, and the district's environment produce the mission dictionary the round plays, built from the catalog's wave vocabulary. Each kind is named on screen like an operation, for what the Striker does there (`WorldMap.kind_label`); the ids (`single`, `dual`, `hold`, `maw`) stay in saved records. The names and card lines are the same at every tier, and nothing on the city map says boss: whether one comes through a Maw stays a surprise (David, 2026-10-26).

Every kind runs about as long as a Breach Night operation. The first build gave Clean Seal one rift and Crossfire one pair, and David finished districts in under a minute (2026-10-26: "only one or two rifts are opening and then no more open for the rest of the mission"). Each kind's `expected_minutes` is computed from its waves by `WorldMap.expected_minutes` the way the catalog's were estimated (rift health over about 13 rift damage per kill, one kill per spawn interval but never faster than about one every 2 s, 6 s per rift opening; a pair feeds the player at once, so it is capped by that cadence rather than summed; a hold rift's own drain adds to the player's). The low end is a hard puncher's clean run (1.3x rift damage), the high end an average puncher's clean run with half again for misses, never past the time a hold ends on its own (2026-11-01; the low end was the average clean run before, and the developer finished under it). Authored at Standard; the tiers multiply the waves later and keep the length (Assist and Operator within 5 percent, Full Resonance about 10 percent longer). Each kind's pressure per minute sits within 15 percent of its sibling operation's at every tier; `Tests/difficulty_audit.gd` checks it ([Difficulty_Tuning.md](Difficulty_Tuning.md)). On paper every kind runs about half its sibling operation's length: three of them make a world operation.

- **Clean Seal** (`single`, was "Single rift"): four rifts in sequence, two shapes repeated and escalating as First Light does (150 health at 3.4 s, then 170 at 3.0 s a little faster with shorter tells, twice over); SEAL FOUR RIFTS, 2 to 4 minutes. "Four rifts in turn, each faster than the last. Read every tell, answer it, and shut the door."
- **Crossfire** (`dual`, was "Dual rift"): two pairs, four rifts with `max_concurrent` 2 and `cluster_rifts` (260 health at 3.1 and 3.6 s, then 280 at 2.8 and 3.2 s, faster with shorter tells); SEAL TWO PAIRS, 3 to 5 minutes. "Two pairs of rifts, out of step in one view. Keep both doors in front of you."
- **Cover the Team** (`hold`, was "Hold the line"): one rift whose health also drains on its own while Chen's team seals it; the player survives the interval. Wave field `hold_seconds`; the rift closes when its health reaches zero from either source. 2500 health at 3.2 s with a 300 s hold: a strong puncher (1.3x rift damage) still takes about three minutes, an average one about three and a half, and nobody waits past five; COVER THE TEAM, 3 to 4 minutes; the hold scales with the tier's rift health, so Full Resonance's team takes 330 s. "Chen's team seals from the pylons. Keep the phantoms off you until they finish."
- **Shut the Maw** (`maw`, was "Maw rift", and "Maw rift, boss" at Full Resonance): The Maw's single large rift and its card time (3 to 6 minutes); SEAL THE MAW. At Full Resonance it carries the boss block and the break odds; below, the flood and the glimpse. The card says the same at every tier: "One vast rift, a heavy flood, and a glimpse of what holds it open. It takes a long chew to shut."

Best score and time are kept per city, district kind, and tier, so a player sees that a Crossfire in Tokyo at Operator has a best.

## Persistence (`GameSettings`)

```
world/home_city = "portland"
world/progress = { city_id: { "ops_done": int, "section": int, "sealed": ["node ids in the current section"] } }
world/assist = false
```

Reset Progress clears world progress and keeps audio and training.

## What happens to the six operations

Retired as a front door on 2026-11-01 (David: "we're moving beyond the original six operations in favor of the world map with difficulty levels. Players simply jump right into the world's war"). The game boots to the world map, which is the main menu. A fresh profile is pointed at Training first (the left panel's leading button); Training Complete offers TO THE FRONT, which opens the home city's section with its region remembered, and WORLD MAP. Chen's priority card on the world map is the suggestion of where help is needed; it points at the home city while that has missions and will get smarter when the war has a heartbeat.

The six operations stay in `MissionCatalog` as data: The Maw district copies the Maw operation's rift, the debug `--mission=<id>` and B deploys still play them, and their results panels still exist for that. Their story arc (Chen's debriefs revealing the Overseer) is in `Ideas_Backlog.md` under Modes and structure, for when Portland or the heartbeat wants an authored run.

## Build order

Built 2026-10-26 on `claude/world-map`, all validated headless (`Tests/validation_runner.gd`: `_validate_world_map`, `_validate_world_menu`, `_validate_hold_the_line`):

1. Model: `Scripts/Core/world_map.gd` (cities, zones, projection, states, tiers, section generator, mission builder) and `GameSettings` world progress.
2. World screen: `Scripts/UI/world_map_view.gd` over `WorldCoastline` in the center panel; the left panel carries world liberation, Chen's priority, the difficulty filter (a dimmer), Training and Settings; the right panel is the picked city's card with Open (`VRWrapPanel.show_world_status`, `show_world_map`, `show_world_city`).
3. City screen: `Scripts/UI/city_operations_map.gd` in the center; the left panel has Back to the world, the liberation bar with the pending operation dashed, and three pips; the right panel is the district card with the tier, the Assist choice for threatened cities only, and Deploy (`show_operations_status`, `show_operations_map`, `show_district_detail`).
4. Round and results: `hold_seconds` in `RiftManager.configure_wave` drains the rift by `maximum_health / hold_seconds` per second while it is open; `GameFlowController` states `world` and `city`, world missions built on deploy from `WorldMap.build_mission`, seals credited in `_finish_world_mission` through `WorldMap.seal_node`, and world results panels that show the line moving (`show_world_report`, `show_world_results_map`, `show_world_results_actions`).
5. Docs and the Menu UX test plan: done with this. Playtest: open.

## Open

- The heartbeat: a server with an AI or an admin moving the fronts over time and narrating it. Until then the fronts only recede.
- Whether to reveal only the next column's district kinds (Path of Exile's trial does this) once there are more than four kinds to choose between.
- Whether the home city should get Chen's priority pull as well as the world.
- Offline tide: no until there is a server, by decision.
