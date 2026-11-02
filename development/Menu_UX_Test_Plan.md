# Quest Menu UX Test Plan

Updated 2026-11-01: the game boots to the world map, which is the main menu (`Scripts/UI/vr_wrap_panel.gd`, `Scripts/UI/world_map_view.gd`, `Scripts/UI/city_operations_map.gd`); the single panel still carries Training Complete, settings, pause, and the confirmations (`Scripts/UI/vr_menu_panel.gd`). Breach Night's six-site city map is gone from the menus. Use a debug build from current `main`.

## Entry and recentering

- Launch while facing away from the intended play direction; hold the Meta button and confirm the menu is centered after Horizon OS recentering.
- The panels remain stationary in world space while the player turns their head.
- Only holding the Meta button moves the panels. Selecting a site or a difficulty, opening settings, pausing, results, opening and closing the universal menu, and taking the headset off and putting it back on all leave them where they are.
- The world map, a city's section, and results are three panels: the war or the city on the left, the map in the middle about 2.45 m away, the city card or the district and Deploy on the right. The side panels stand off the middle one's edges, turned 30° in toward the player. Everything sits at eye height inside the comfortable field of view; Deploy needs at most a small head turn to the right, never a turn of the shoulders.
- Settings, pause, the confirmations, Training Complete, and the XR suspended page are one panel straight ahead, as before.

## Pointer interaction

- Both controllers show a laser only when a menu is visible.
- Pointing at a button or a map site visibly highlights it, on all three wrap panels.
- Pulling and releasing the trigger activates exactly one action, on release.
- Lasers disappear during combat and training and reappear on pause, XR suspend, results, and Training Complete.
- Buttons are selectable without wrist twisting or crossing hands, including the side panels' outer edges.
- Results respond to both lasers after victory and after defeat (regression check for the earlier Quest 3 issue).
- Map sites are big enough to hit with the laser on the first try. Locked sites do not highlight or respond.

## World map

Ask a player who has not seen the project, without coaching:

1. Where is the war? Expected: the two hatched regions behind the magenta lines. The fronts do not advance; they fall back toward their tear as cities inside them are liberated, and a liberated city wears a cyan ring.
2. Which cities can you fight in? Expected: the lit markers (cyan, amber, magenta); grey dots are safe and have no missions; dark dots are consumed.
3. How do you play on easy? Expected: the EASY filter on the left, or a cyan (threatened) city.
4. How do you start? Expected: point at a region, then a city, then **Open** on the right panel, then a district, then **Deploy**.

Pass condition: all four within 15 seconds.

- The whole world opens with PICK A REGION: six outlined regions, one per continent (North America, South America, Europe, Africa, Asia, Oceania), each named with how many of its cities are in reach. No outline crosses into another continent: Asia stops north of Australia, Europe and Africa split at the Mediterranean, and Oceania covers Australia and New Zealand. A region lights when pointed at, and the trigger picks the region the ray is inside, even at its edge next to a neighbor; Europe is the smallest outline and must still be easy to hit. No city can be picked from here.
- Picking a region eases the map to it over about half a second; the header names the region. Nothing can be pressed on the map until it settles. Its cities are then the buttons, large enough to pick in the headset: check the Toronto / New York / Chicago cluster and Vancouver / Portland. Cities outside the region are drawn but not pickable. If the picked city was elsewhere, the card switches to home or the region's most fought-over city.
- **Whole World** at the bottom of the map, or Escape on desktop, eases back out. The World Map button on the main menu always starts at the whole world.
- The picked city carries a white ring and fills the right panel. Nothing starts until Open. Open closes the map in on the city with a ring locking onto it and its name; the city screen appears only after the zoom ends, in under half a second. Triggering anything during that zoom does nothing.
- From the city screen, World Map returns to the same region, easing out from the city.
- Lines, markers, and labels stay the same size on screen at every zoom; the land fills in at every step of the zoom (no missing continents).
- The filter dims cities that do not match at every zoom, and dims regions with nothing that matches; ALL is marked (●) on a fresh profile. The legend in the center header names the colors.
- The right panel shows the city's state, difficulty, distance from the front, liberation, resistance, tier, and operations done. Open leads on a playable city; a safe or consumed city shows a disabled button with its difficulty word (NO MISSIONS) instead. The home city's card also has Breach Night, back to the six operations.
- World liberation on the left is the average of every city's liberation. Chen's priority names the home city while it has missions.
- The left panel has Training (leading for a new recruit) and Settings. Settings returns to the world map.
- All three panels fit without scrolling or clipped text for the home city, a safe city, a consumed city, and an overrun city.

## City operations

- The center shows one section: up to three columns of districts, the first column open, the rest dashed and locked behind a magenta line one column right of the last seal. Sections are not labeled or numbered.
- A sealed district carries a check and lights its edges cyan; the open ones after it have a cyan edge. Picking a district fills the right panel. Nothing starts until Deploy.
- Each district names what the Striker does there: CLEAN SEAL, CROSSFIRE, COVER THE TEAM, or SHUT THE MAW, the same at every tier. Ask the tester what each one means before they play it; expected: one rift, two at once, protect Chen's team, a big one. No district, card, or button says boss, a break, or to take the other district; a Maw card reads as a vast rift, a heavy flood, and a glimpse of what holds it open.
- Deploy names the tier the city plays at (threatened = STANDARD or ASSIST, in danger = OPERATOR, overrun = FULL RESONANCE). Only a threatened city shows the STANDARD / ASSIST choice; it is remembered across cities and restarts.
- The left panel has Back to the world map, the liberation percentage with the city's resistance word, a bar whose dashed part is the operation in progress, and three pips for this operation's seals.
- A world mission's results are the city map. Ask the tester, without coaching, how to start the next mission; expected: point at a lit district in the middle and press Deploy, within 10 seconds and without going anywhere else first.
- After a seal: the center keeps MISSION COMPLETE with the time and score over the section, the district just sealed ringed white and the old line faint behind the new one; the next open district is already picked, its card and a filled Deploy on the right. The left says THE LINE MOVED with the liberation number and has Replay (the district again, for its time), World, and Settings. Between them the left shows the round's workout, as Breach Night results do, and YOUR BEST • <MISSION> AT <TIER> with the time, score, and medal; the center's score carries the round's medal and NEW BEST SCORE as on Breach Night.
- A district card shows YOUR BEST and BEST SCORE with its medal for that mission kind in this city at the city's tier, or a dash where there is none.
- Picking another open district on the results map swaps the right panel to its card; locked and sealed districts do not press. Deploy starts the picked one at the city's tier. A trigger held through the end of the fight presses nothing: the first press counts only after it is released.
- After a defeat the center reads OPERATION ENDED and the left THE BREACH HELD. Retry leads on the right at the same tier, with Review Training under it; the open districts still press, and picking one puts its card and Deploy up instead.
- The third seal advances the city: the left says OPERATION COMPLETE and liberation rises by one operation's share (UP FROM the old value), and the center shows the next section, its first column open and picked, under OPERATION COMPLETE. The pips clear.
- Replay after a seal plays the sealed district again; its time and score count, the left then says THE LINE HELD, and the line does not move.
- Settings from results returns to the same results, with the same district picked.

## Training

Training is no longer a menu: it is Dr. Chen's training chamber ([Tutorial_Plan.md](Tutorial_Plan.md)). What the menu has to get right around it:

- On a fresh profile, the world map's Training button leads (Start here); after training it reads Replay. Open and Deploy work regardless. Once training is done (finished or ended from pause), the city map returns to its usual layout.
- Selecting Training Chamber hides the menu and lasers and starts the chamber. No other trigger press starts it.
- The menu button pauses training at any point, including Chen's introduction before the rift appears. The pause panel reads Resume Training, Settings, End Training, and Chen stops mid-line until Resume.
- End Training needs no confirmation, returns to the world map, and counts training as done.
- After Chen signs off, Training Complete offers To the Front (primary, naming the home city, its state and its tier; it opens the home city's section, and the way back to the world lands on its region), Replay Training, and World Map. Replay plays the whole tutorial again, identical to a first run.
- Headset removal during training shows the XR suspended page and holds the chamber where it is.

## Settings

- Play My Own Music switch shows its state; when on, the Music Volume stepper is hidden and the soundtrack is silent.
- Music (when shown), Effects, and Haptics steppers show their current value and explain what they affect.
- Reduced Flashes shows its state.
- Changing any setting leaves the list scrolled where it was, with no jump to the top. Opening settings again starts at the top.
- Reset Progress asks for confirmation and explains that audio and training are kept.
- Back returns to the correct origin: the world map, a city's section, results, or pause.
- Settings and progress persist after an app restart.

## Pause, suspend, and results

- Pause shows Resume Mission as primary, Settings as secondary, End Mission as destructive with a confirmation page. In training the same panel reads Resume Training, Settings, End Training.
- Headset removal shows the XR suspended page; Resume When Ready is required to continue.
- Results wrap around like the city map. Middle: the outcome with the difficulty on its own line (ALL RIFTS SEALED • OPERATOR), then MISSION COMPLETE with the completion time after a victory (with NEW BEST TIME when it beats the stored best, SEALED IN otherwise) and the score with the medal the round earned beside it (NEW BEST SCORE under it when it beats the stored best, otherwise the medal's name: SILVER • SCORE; a first clear and a defeat call no new best, and a defeat earns no medal), the map, and the operation's debrief line. After a first clear the site turns sealed, the front moves past it with the old front drawn faint, and the next site turns live.
- Left: the city's reclaimed share (UP FROM the old share when it moved), THE LINE MOVED, THE LINE HELD (a replay), or THE BREACH HELD (a defeat); then the round's workout: punches, lure crits, best chain, active time, kcal (marked as an estimate, ~42 KCAL (EST.)), rifts sealed, and a line each of gold, blue, and blocks and of dodges, missed, and wrong hand. The workout shows after a defeat too. Last, YOUR BEST at that difficulty: the time, the score, and the best medal. Ask the tester what KCAL (EST.) means and whether the punch count feels right for the round they just played.
- Right, after a victory that unlocks a site: the next site and a filled Deploy, then Retry and City Map. Otherwise Retry is the filled button, and after a defeat Review Training sits between Retry and City Map and starts the training chamber. Retry and Deploy keep the difficulty the mission was played at.

## In-fight readability

- Bracer panel text is readable at a glance mid-combat.
- Chen captions are legible and do not cover the life force bar.
- Rift compass chevron is noticed by an untold tester when a rift opens behind them.
- At Full Resonance, Chen's countdown line ("Full resonance. The gauntlets draw on your whole body. Legs too." or "More power. More cost. Clear the space around you.") plays before her mission line, and neither is cut off.

## Visual quality

- Text is readable on Quest 3 without leaning, on the side panels as well as the middle one. Map labels are the smallest text (16 to 18 px); check them first.
- No button text clips at standing eye height.
- Hover and selected states remain legible for common color-vision deficiencies; do not rely on color alone. Sites also differ by shape: check, rift, lock.
- UI audio stays below critical gameplay cues and Chen.
- No visible pixel shimmer or excessive aliasing at the panel distance, including the map's hatching and the side panels seen at an angle.
