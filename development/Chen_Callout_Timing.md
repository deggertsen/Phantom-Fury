# Chen's incoming callouts

Updated 2026-11-08.

First-sighting lines previously came from a half-second scan of the `phantom` group. That group includes bodies that are already dissolving. The scan could repeatedly requeue a sighting until the five-second conversational cooldown allowed it to play, without checking whether the phantom had already been punched or dodged. Ray/Eel/sweep warnings already triggered at the start of their telegraph, but also had no target check at playback.

First sightings now trigger once per spawn, after the node is ready and the spawner has applied its settings. Extras-layer pink warnings use the same spawn notification; Ray/Eel/sweep movement calls still trigger when their telegraph starts, after any lane wait.

Each incoming line carries a weak reference to its source. It gets the next free voice slot without the conversational cooldown, waits at most 0.6 seconds, and requires at least 0.5 seconds of conservative approach time when it can start. Punchable phantoms use distance to punch reach at maximum approach speed; Spearfins use their locked charge target; sweeps use remaining telegraph plus travel to contact. Resolved, dissolving, freed, cleaned-up, held, escorting, and returning punchable phantoms cannot produce a late warning. The voice queue rechecks the source before starting playback.

Chen still speaks one line at a time and finishes a line already in progress. If there is no timely slot, the incoming warning is skipped. An introduction is only marked as delivered when it actually starts, so a later spawn can introduce that species. Training's prefix lock and scripted boss dialogue remain authoritative. Recordings and combat movement are unchanged.

`Tests/validation_runner.gd` covers immediate spawn delivery for all six species, a queued warning invalidated by a punch or dodge, a later live arrival after a skipped introduction, close/freed/cleaned-up targets, a busy voice queue, and training/boss locks. Before releasing a new Quest build, play a busy mission with pinks, Rays, and Eels and confirm that the first audible words precede the required action; also check pause/resume and the tutorial on headset.
