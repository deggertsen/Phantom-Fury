# Phantom Fury: Resonance Rising

A stationary VR fitness-combat game for Meta Quest, built in Godot 4.7.1 with OpenXR and godot-xr-tools. You pick a city on a world map at war, deploy to a breach site in one of its districts wearing Dr. Chen's Ethereal Resonance Matrix (ERM) gauntlets, and physically punch, block, duck, and dodge phantoms pouring out of dimensional rifts until every rift is sealed and every phantom is gone. Each seal pushes the front line back.

The goal of the project is a workout you want to come back to because the world needs saving, not because a timer told you to. Everything below describes the game as it exists in this repository today. The game was called Phantom Fray until 2026-10-24; the repository folder, the release keystore, and the ElevenLabs key folder on the build machine keep that name. The Android package is `com.phantomfury.resonancerising`. Plans live in [development/Production_Roadmap.md](development/Production_Roadmap.md); ideas not yet scheduled live in [development/Ideas_Backlog.md](development/Ideas_Backlog.md).

## How it plays

- **Stationary, physical.** No artificial locomotion. You turn, duck, and take a step to the side. Everything comes to you.
- **Grip, then strike.** Hold grip and punch. Closing the grip powers the gauntlets up: a surge runs down the bracer, the knuckles light, and a tick lands in the palm. Opening it powers them down. A strike counts once a phantom is in reach, which is also when it lunges. Jabs, hooks, and uppercuts all work, and the Angler's glowing lure hangs where the matching punch lands. Punch harder and more energy goes into the rift: rift damage runs from 0.85x for a soft punch (2 m/s) to 1.3x for a hard one (6 m/s), and the lure crit is worth more than either.
- **Six phantom rules, each a different movement.** Yellow and blue are always the steady stream and green the rarest; pinks, Rays, and Eels ride on top of it, each on its own timer, so the dodges land between punches.

| Color | Species | Rule | What the body does |
|---|---|---|---|
| Yellow | Angler | Left hand only. Strike the lure for a resonance crit. | Left jabs, hooks, uppercuts |
| Blue | Angler | Right hand only. Strike the lure for a resonance crit. | Right jabs, hooks, uppercuts |
| Green | Carapace | Catch it with both hands inside a short window. | Two-hand block |
| Pink | Spearfin | Cannot be punched. Aims its bill at you, then charges. | Step out of its path |
| Orange | Ray | Cannot be punched. A wide manta gliding in at head height. Medium and Hard. | Duck under it (Medium), squat under it (Hard) |
| White | Eel | Cannot be punched. Sweeps across the floor at your feet. Hard only. | Jump it |

- **Rifts are the objective.** Each phantom you resolve damages the rift it came from. Sealing a rift stops its spawning, but the phantoms it already released keep coming. A mission is won when every rift is sealed and the last straggler is dealt with. There is no time limit: the wrist clock counts up from 0:00 and your fastest victory is kept.
- **Life force is the stakes.** The gauntlets run on your own life force. A phantom that reaches your head possesses you: it vanishes, drains 20 of 100, and your vision frosts and distorts. Life force recovers after three clear seconds. At zero the gauntlets' failsafe fires, the recovery team pulls you out, and the mission is failed. Strikers are never consumed; you go back in and try again.
- **Score and chain.** Every resolve adds to a chain multiplier up to 3x. Resonance crits and on-arrival hits grow it faster. A wrong hand or a possession resets it. Your best score and best time are kept per city, mission, and difficulty, and a victory earns a bronze, silver, or gold medal against the mission's par.
- **The workout on results.** Every results screen shows the round's workout, after a defeat too: punches, lure crits, best chain, active time, an estimated calorie count, rifts sealed, and how each phantom was answered. See [development/Workout_Stats.md](development/Workout_Stats.md).
- **Training with Dr. Chen.** Training is a played scenario, not a manual. Chen introduces herself and the war, then walks you through everything in a fight inside the RSF training chamber, where the rift and the phantoms are holograms she can pause: she freezes each one in reach at the moment you would punch it, explains what matters, and waits for the right move. One possession is let through on purpose and she has you look at your left glove, where your life force shows; punch power is shown with damage readouts, and it ends on a short live wave. About five minutes; training cannot fail, and ending it from pause counts as done.
- **Dr. Chen on comms.** She calls you Recruit in training and Striker, a member of the Resonance Strike Force, once you deploy. Fully voiced callouts for rift bearings, first contact with each species, wrong-hand corrections, chain milestones, life force warnings, possession, and debriefs that know whether this is your first attempt, a retry after the failsafe, a replay, a flawless seal, or a new best. Captioned on the wrist panel.
- **Your own music.** A settings switch silences the soundtrack so a playlist from any music app plays through the mission while Chen stays audible.
- **Three difficulty levels, set by the war.** There is no difficulty button: a city's level comes from how close the front is. Threatened cities play Easy, cities in danger play Medium, and overrun cities play Hard (Full Resonance). Each step up brings more phantoms, a bit faster, and new body movements; a possession drains the same 20 at every level. Inside a threatened city the district card offers Assist, a session choice that slows phantoms, lengthens tells, and softens contact without changing the city. Every Hard mission asks for squats and jumps; clear the space around you.

## The war today

Training comes first: a new recruit is pointed at Dr. Chen's training chamber (see How it plays), and Training Complete offers TO THE FRONT, straight into their home city. After that the game boots straight into the world map, which is the main menu. The model is [Scripts/Core/world_map.gd](Scripts/Core/world_map.gd); the design is [development/World_Map_Design.md](development/World_Map_Design.md).

- **Two fronts.** The Breach opened at Jakarta on day 0 and the Second Tear at Chicago on day 31. Everything inside a front is consumed. The map is split into six regions, one per continent; pick a region, then a city.
- **A city's state is its distance to the nearest front.** Overrun (closest) plays Hard, in danger plays Medium, threatened plays Easy. Cities farther out are safe and have no missions; consumed cities are out of reach.
- **Operations.** Opening a city zooms into one section of it: districts in three columns joined into a short path. Pick a district in the first column, then a linked one, then the third, which is always the level's finale. Three seals make an operation. Each operation fills the city's liberation bar and pulls its front back toward the tear, so consumed cities behind the line come back as overrun and open up. Liberating every other city of a front turns the tear's own city overrun, the last fight of that front; liberating it removes the front. Fronts never advance yet: that waits for a server to move them.
- **Each level has its own missions** ([development/Difficulty_Matrix.md](development/Difficulty_Matrix.md)). The first two columns deal the level's regular missions; the third is its finale.

| Level | Missions | Finale | About |
|---|---|---|---|
| Easy (threatened) | Clean Seal, Cover the Team | First Charge | 3.5 min |
| Medium (in danger) | Flurry, Crossfire, Low Ceiling | Close the Sector | 5 to 6 min |
| Hard (overrun) | Flurry, Storm, Undertow, Last Stand | Shut the Maw | 5 to 7 min |

- **Bosses.** Hard's finale, Shut the Maw, is one vast rift. The first Maw a profile faces at Hard always breaks, then about one in three does (never three in a row without a boss): a false seal, a turn, and a fight against its tentacles answered with squats, jumps, and push-ups until it loses its hold and retreats. At Medium, Close the Sector is sometimes the Maw's lighter form (ducks, jumps, and its escort, no slams); the card never says which. Easy has no bosses.
- **Districts play at seven breach sites** (dead city, harbor, summit, stadium, salt flat, small town, farmland), picked from the district's name.

Every card shows its expected time and, once won, the best time, score, and medal at that level. The times are estimates from the wave tables until timed headset runs replace them; every finished round is logged on the headset (`user://run_log.csv`, see [development/Difficulty_Tuning.md](development/Difficulty_Tuning.md)). The war is local to each headset for now.

## Controls

| Action | Quest controller | Desktop fallback |
|---|---|---|
| Strike | Hold grip and punch | none |
| Menu select | Point and pull trigger | none |
| Deploy, start training, resume | Button on the panel | Enter or Space |
| Pause, or back out of a city or region | Menu button, or Back on the panel | Esc |
| Training | Button on the panel | T |
| Settings | Button on the panel | S |
| Recenter | Hold Meta button | none |

Debug builds also accept `H` to take a hit, `R` to reset life force, `B` on the world map for The Maw at Full Resonance (`Shift+B` forces the boss through; it records nothing), and `P` for one push-up on a spent tentacle. `--mission=<id>` on the command line deploys one of the original six operations still kept as data in [Scripts/Core/mission_catalog.gd](Scripts/Core/mission_catalog.gd) (debug only; the world map's missions are built from its wave vocabulary), and `--tier=<id>` sets that deploy's difficulty.

## Running and validating

Godot 4.7.1 exactly. The desktop fallback runs without a headset for menu, flow, and art review.

```bash
godot --path .
```

Automated validation (resource loading, SFX takes, variant rules, life force arithmetic, strike window, mission catalog, rift stragglers, elapsed timer and best time, the world map, its regions, fronts, district missions and sites, and its menus and results, difficulty tiers and their records, the difficulty audit of every level's missions, the run log, menu surfaces, pink dodge, Rays and Eels, squat, push-up, and jump detection, the resonance sweep, The Maw's break odds, boss fight, and glimpse, the training hold, punch power, a full training run, session stats, and medals):

```bash
tools/validate_project.sh
```

Art and play-through stills for review, written to the gitignored `reports/` folder:

```bash
godot --path . --xr-mode off --resolution 1600x900 res://Scenes/Debug/art_capture.tscn
```

```bash
godot --path . --xr-mode off --resolution 1600x900 res://Scenes/Debug/play_capture.tscn
```

The whole training chamber, played through by a stand-in recruit, with a still at each paused hologram:

```bash
godot --path . --xr-mode off --resolution 1600x900 res://Scenes/Debug/play_capture.tscn -- --tutorial --art-label=tutorial
```

Chen's lines are generated from `Assets/Audio/VO/chen/chen_lines.json` with `tools/generate_elevenlabs_vo.ps1` and checked against the script with `tools/check_vo.ps1`.

Quest builds: [development/Quest_Export_Guide.md](development/Quest_Export_Guide.md).

## Project layout

- `Scripts/Core/` world map (cities, fronts, states, sections, and the missions each level builds), mission catalog (wave vocabulary and the original six operations, kept for debug deploys and as The Maw's template), difficulty tiers, round controller, game flow, settings, session stats, medals, run log, and the tutorial director that runs training
- `Scripts/Bosses/` The Maw's boss phase: the turn, tentacles, slam
- `Scripts/Hazards/` the resonance sweep
- `Scripts/Phantoms/` phantom base arc, Angler (yellow, blue), Carapace (green), Spearfin (pink), Ray (orange) and Eel (white) on the sweep creature
- `Scripts/Rifts/` rift director (which rifts open where) and rift manager (spawning, the extras layer, health, closure, stragglers)
- `Scripts/Player/` XR origin, hands and strike detection, tracked hands, squat and push-up detectors, life force and its feedback
- `Scripts/Presentation/` creature meshes, breach sites and their dressing, arena, training chamber dome, gauntlets, VFX, compass and bearings
- `Scripts/Audio/` Chen comms, music intensity, SFX takes
- `Scripts/UI/` world map and city views, world-space menu panels and presenter, medal badge, wrist HUD
- `Tests/` the validation runner and the difficulty audit
- `Scripts/Debug/` performance monitor and capture scenes
- `Assets/Audio/VO/chen/` Chen's script (`chen_lines.json`), takes, and the ElevenLabs manifest
- `development/` design, production, and release documents
- `tools/` Quest build scripts, validation, VO generation and checking

## Where this is going

The design intent, in priority order. Details and status in the roadmap.

1. **Fitness first.** Session stats are built. Still to come: workout-length framing in the menu (a quick hold, an operation set, a longer session) and Meta fitness tracking, so there is a reason to sweat that is bigger than a score.
2. **Replay value.** Best scores and medals are built. Still to come: an endless hold mode, a daily breach everyone fights, and leaderboards.
3. **Narrative hooks.** The world map war is built and local to each headset. Next is its heartbeat: a server where an AI or an admin moves the fronts over time and narrates the war against the Overseer, so every Striker's seals push the same line, in the spirit of Helldivers 2.
4. **Location variety.** Seven breach sites are built; districts such as the Airport, Quarry, University, Foundry, and Rail Yards may earn their own.
5. **Difficulty by the war.** Three levels, each with its own missions, set by a city's distance to the front. Push-ups can be done with the controllers hanging on their straps and the hands tracked (simultaneous hands and controllers). Still to come: timed headset runs to tune every level, and per-district twists once the missions are balanced. See [development/Difficulty_Matrix.md](development/Difficulty_Matrix.md) and [development/Exercise_Mechanics_Exploration.md](development/Exercise_Mechanics_Exploration.md).

## Lore

Title: "Phantom Fury: Resonance Rising"

In 2142, humanity's reach exceeded its grasp. Our experiments with interdimensional energy, meant to revolutionize space travel, instead tore the fabric of reality. On the day known as "The Breach," ethereal entities we called "Phantoms" began pouring through microscopic rifts, impervious to conventional weapons and hungry for life force.

Dr. Elara Chen, the brilliant mind behind the ill-fated experiments, had created a revolutionary technology called the "Ethereal Resonance Matrix" (ERM). Originally designed to safely interact with interdimensional energies, ERM became humanity's unexpected salvation.

As cities fell silent and governments crumbled, Dr. Chen made a startling discovery. By inverting the ERM's energy signature, it could negate Phantom energy, effectively destroying them. However, this came with a catch: the ERM required a direct connection to a living being's life force to function. Projectile weapons were impossible; the fight against the Phantoms would have to be up close and personal.

Enter the Resonance Strike Force (RSF), a desperate initiative to turn the tide. You are one of the newest recruits, chosen for your exceptional physical abilities and mental fortitude. Your mission: master the ERM gauntlets and take the fight to the Phantoms.

As you progress through training and into active duty, you'll uncover crucial information:

1. The Phantoms aren't just random invaders, but pawns of a greater intelligence dubbed "The Overseer."
2. Each Phantom has a "resonance point" where its connection to The Overseer is strongest. Striking these points causes maximum disruption to the Phantom network.
3. Your actions aren't just defeating individual Phantoms, but systematically weakening the entire invasion force.

Your missions with the RSF will be twofold: closing the dimensional rifts scattered across the globe and gathering crucial intelligence on the Phantoms and their mysterious Overseer. Each successful operation not only pushes back the invasion but also pieces together the puzzle of the Phantoms' origin and nature.

Throughout the story, we can explore:
- The ethical implications of using life force-powered technology
- The camaraderie and rivalries within the RSF
- The weight of being humanity's last, best hope

This setup maintains the epic scale of our conflict while focusing on the player's personal journey from recruit to humanity's champion. It also leaves room for future expansions - perhaps discovering other dimensions affected by The Breach or exploring the long-term effects of ERM use.

Rift-closing missions: These could be intense, time-pressured battles where you need to fight off waves of Phantoms while Dr. Chen's team works to seal a rift.
Intelligence-gathering missions: These might involve capturing specific Phantom types or targeting Phantoms that seem to be relaying information.
Escalating challenge: As you close more rifts and learn more about the Phantoms, they could adapt their strategies, introducing new types of enemies or behaviors.
Story progression: Each bit of intel could reveal more about the Phantoms' hierarchy, the nature of the Overseer, and potentially ways to strike at the heart of the invasion.
Final confrontation: All of this could build up to a climactic mission where you use everything you've learned to open a rift to the Phantoms' dimension and take the fight to the Overseer.

### The Phantom Threat

1. Phantom Physiology:
   - Phantoms are energy beings composed of negative life force.
   - They exist in a state of constant hunger, driven to consume positive life energy to maintain their form in our dimension.

2. The Consumption Process:
   - When a Phantom touches a living being, it begins to siphon life force through a process we could call "ethereal osmosis."
   - The victim experiences a sensation of extreme cold, followed by weakness, disorientation, and eventually, total systemic failure.
   - The process can take anywhere from seconds to minutes, depending on the size and power of the Phantom.

3. Visible Effects:
   - As life force is drained, victims develop a pale, almost translucent appearance.
   - Glowing, vein-like patterns may appear on the skin, tracing the path of energy extraction.
   - In the final stages, victims may emit a faint, ghostly glow before collapsing.

4. Environmental Impact:
   - Areas with high Phantom activity become cold and lifeless.
   - Plants wither, animals flee, and the very air seems to become thin and hard to breathe.
   - In severe cases, the laws of physics may begin to break down, causing localized reality distortions.

5. Phantom Evolution:
   - As Phantoms consume more life force, they grow larger and more powerful.
   - Some may evolve specialized abilities, like faster movement or the power to drain life force from a distance.
   - The most powerful Phantoms can drain entire crowds simultaneously.
   - The largest cannot come through a rift at all until they have drained a city's worth of life force, which is why they rise at dead cities. Holding that shape in our world burns them out: such a Phantom drains away on its own, and a Striker who outlasts it forces it back through its rift before the rift closes. These Phantoms are not destroyed; each crossing is an attempt to gather enough energy to hold a permanent presence in our world, and every Striker it drains buys it more time.

6. The Hive Mind Effect:
   - The Overseer uses the consumed life force to create more Phantoms and strengthen its control over Earth's dimension.
   - This creates a feedback loop: more consumption leads to more Phantoms, which leads to more consumption.

7. Humanity's Desperate Measures:
   - Conventional weapons are useless, leading to panic and mass exoduses from cities.
   - Some humans, in desperation, have formed cults that worship the Phantoms, offering themselves as willing sacrifices.
   - Governments resort to extreme measures like scorched earth tactics, hoping to deprive Phantoms of life force to consume.

8. The ERM Advantage:
   - The ERM gauntlets don't just destroy Phantoms; they can also temporarily reverse the life force drain in recently affected victims.
   - This makes RSF Strikers not just warriors, but potential saviors, adding an extra layer of urgency to their missions.

9. The Failsafe and the Recovery Team:
   - The gauntlets draw on the Striker's own life force, so Dr. Chen reads the Striker's vitals live through them. That is how she knows, over comms, the moment a Striker starts to fade.
   - If a Striker's life force collapses, the gauntlets' failsafe inverts the ERM and dumps its whole charge at once. The burst throws every Phantom off the Striker and stops the drain, but it knocks the Striker out and leaves the gauntlets spent.
   - An RSF recovery team waits at the pylon line on every deployment. When the failsafe fires, they go in and drag the Striker clear. The Striker survives, but the breach stays open, and the failsafe has to recharge before the next attempt.
   - Strikers are never consumed in the field. Failing a mission means being pulled out, not dying, which is why a Striker can go back into the same breach and try again.
