extends Node

const STAGE_SIZE := Vector2i(1344, 652)

var _menu: VRMenuPanel
var _stage: Control
var _left: VRWrapPanel
var _center: VRWrapPanel
var _right: VRWrapPanel

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/menu-states"))
	_build_wrap_stage()
	await _capture_city_map()
	await _capture_results()
	await _capture_world()
	_stage.queue_free()
	# The panel is drawn at the headset viewport size; the default 1152x648 window cut off its bottom rows.
	get_window().size = Vector2i(1280, 780)
	_menu = preload("res://Scenes/UI/vr_menu_panel.tscn").instantiate() as VRMenuPanel
	add_child(_menu)
	await _capture_tutorial()
	await _capture_settings()
	await _capture_pause()
	print("MENU CAPTURE COMPLETE")
	get_tree().quit()

## The three wrap panels laid flat side by side, at their headset pixel sizes.
func _build_wrap_stage() -> void:
	get_window().size = STAGE_SIZE
	_stage = Control.new()
	_stage.size = Vector2(STAGE_SIZE)
	add_child(_stage)
	var backdrop := ColorRect.new()
	backdrop.color = Color("04060d")
	backdrop.size = Vector2(STAGE_SIZE)
	_stage.add_child(backdrop)
	var side := Vector2(VRWrapPanel.SIDE_PIXELS)
	var middle := Vector2(VRWrapPanel.CENTER_PIXELS)
	_left = _add_wrap_panel(Vector2(16, 16), side)
	_center = _add_wrap_panel(Vector2(352, 16), middle)
	_right = _add_wrap_panel(Vector2(1008, 16), side)

func _add_wrap_panel(at: Vector2, panel_size: Vector2) -> VRWrapPanel:
	var holder := Control.new()
	holder.position = at
	holder.size = panel_size
	_stage.add_child(holder)
	var panel := VRWrapPanel.new()
	holder.add_child(panel)
	return panel

func _show_city(profile: Node, selected_id: String, training_first: bool = false) -> void:
	var entries := MissionCatalog.operation_entries(profile)
	_left.show_city_status(entries, training_first)
	_center.show_city_map(entries, selected_id)
	for entry in entries:
		if entry.get("id", "") == selected_id:
			_right.show_site_detail(entry, MissionCatalog.tier_from(profile), training_first)

func _capture_city_map() -> void:
	var profile := _profile(["first_light", "widen_the_ring"])
	_show_city(profile, "chens_gambit")
	await _capture("city-map.png")
	_show_city(profile, "first_light")
	await _capture("city-map-replay.png")
	profile.difficulty_tier = DifficultyTier.FULL_RESONANCE
	_show_city(profile, "chens_gambit")
	await _capture("city-map-full-resonance.png")
	profile.free()
	var recruit := _profile([])
	_show_city(recruit, "first_light", true)
	await _capture("city-map-new-recruit.png")
	recruit.free()

func _capture_results() -> void:
	var cleared := _profile(["first_light", "widen_the_ring", "chens_gambit"])
	cleared.best_times["chens_gambit"] = 252.0
	cleared.best_scores["chens_gambit"] = 31400
	_show_results(_report(cleared, &"victory", "chens_gambit", 2, "double_breach", 252.0, 280.0, "Chen: It knows your resonance now. This was the opening move. Not the end of the war."))
	await _capture("results.png")
	_show_results(_report(cleared, &"defeat", "double_breach", -1, "", 0.0, 0.0, "Chen: The pair drank you. Take the left door before their scouts overlap."))
	await _capture("results-defeat.png")
	cleared.free()
	var reclaimed := _profile(["first_light", "widen_the_ring", "chens_gambit", "double_breach", "open_arc", "the_maw"])
	_show_results(_report(reclaimed, &"victory", "the_maw", 5, "", 301.0, 0.0, "Chen: The Maw is shut. It will remember how long you made it chew."))
	await _capture("results-reclaimed.png")
	reclaimed.free()

func _show_results(report: Dictionary) -> void:
	_left.show_city_report(report)
	_center.show_results_map(report)
	_right.show_results_actions(report)

## The same shape GameFlowController hands the presenter, at Standard.
func _report(profile: Node, outcome: StringName, mission_id: String, sealed_before: int, next_id: String, seconds: float, previous_best: float, debrief: String) -> Dictionary:
	var entries := MissionCatalog.operation_entries(profile)
	var by_id := {}
	for entry in entries:
		by_id[entry.get("id", "")] = entry
	var score := 31400 if outcome == &"victory" else 4120
	var best_score := int(profile.best_score(mission_id))
	var thresholds := MissionMedals.operation_thresholds(mission_id, DifficultyTier.STANDARD)
	return {
		"outcome": outcome,
		"score": score,
		"debrief": debrief,
		"seconds": seconds,
		"previous_best": previous_best,
		"best_seconds": float(profile.best_time(mission_id)),
		"tier": DifficultyTier.STANDARD,
		"mission": by_id.get(mission_id, {}),
		"next": by_id.get(next_id, {}),
		"sealed_before": sealed_before,
		"entries": entries,
		"offer_training": outcome == &"defeat",
		"stats": _stats(outcome),
		"medal": MissionMedals.medal_for(score, thresholds) if outcome == &"victory" else "",
		"previous_best_score": 28900 if outcome == &"victory" else 0,
		"best_score": best_score,
		"best_medal": MissionMedals.medal_for(best_score, thresholds),
	}

## A round's SessionStats as results carry them: a strong victory, or a defeat partway in.
func _stats(outcome: StringName) -> Dictionary:
	var stats := SessionStats.new()
	var victory := outcome == &"victory"
	stats.punches = 186 if victory else 74
	stats.rejected = 9 if victory else 11
	stats.wrong_hand = 3 if victory else 5
	stats.by_variant = {"yellow": 34, "blue": 31, "green": 18, "pink": 15} if victory else {"yellow": 14, "blue": 12, "green": 6, "pink": 4}
	stats.by_kind = {"two_hand_block": 18, "dodge": 15} if victory else {"two_hand_block": 6, "dodge": 4}
	stats.crits = 27 if victory else 6
	stats.misses = 4 if victory else 13
	stats.longest_chain = 41 if victory else 9
	stats.rifts_sealed = 12 if victory else 3
	stats.active_seconds = 252.0 if victory else 131.0
	return stats.to_report()

## A settings object with these operations sealed and the first two timed and scored, never saved to disk.
func _profile(cleared: Array) -> Node:
	var profile: Node = load("res://Scripts/Core/game_settings.gd").new()
	profile.cleared_missions = PackedStringArray(cleared)
	var times := {}
	if "first_light" in cleared:
		times["first_light"] = 94.0
	if "widen_the_ring" in cleared:
		times["widen_the_ring"] = 342.0
	profile.best_times = times
	# First Light at gold, Widen the Ring at silver, so the map and cards show both.
	var scores := {}
	if "first_light" in cleared:
		scores["first_light"] = int(MissionMedals.operation_thresholds("first_light", DifficultyTier.STANDARD)[MissionMedals.GOLD]) + 240
	if "widen_the_ring" in cleared:
		scores["widen_the_ring"] = int(MissionMedals.operation_thresholds("widen_the_ring", DifficultyTier.STANDARD)[MissionMedals.SILVER]) + 480
	profile.best_scores = scores
	return profile

# --- World map -----------------------------------------------------------------------------

## The world front, a city's section, and world results, in the shapes GameFlowController builds.
func _capture_world() -> void:
	var profile := _profile([])
	profile.world_progress = {}
	var home_id := WorldMap.home_city_id()
	var entries := WorldMap.city_entries(profile)
	var home := _entry(entries, home_id)
	var tokyo := _entry(entries, "tokyo")
	var world := {
		"liberation": WorldMap.world_liberation(profile),
		"filter": "all",
		"home_id": home_id,
		"priority": {"city_id": home_id, "body": "%s. The front is about %d km out and it does not stop. Hold home ground." % [home["name"], WorldMap.kilometers(float(home["distance"]))], "bonus": "%s  •  %s" % [home["difficulty_label"], home["resistance"]]},
		"training_first": true,
		"assist": false,
	}
	_left.show_world_status(world)
	_center.show_world_map(entries, home_id, world)
	_right.show_world_city(home, world)
	await _capture("world-map.png")
	world["region"] = "north_america"
	_center.show_world_map(entries, home_id, world)
	_center.world_map_view().finish_zoom()
	await _capture("world-map-region.png")
	world["filter"] = "hard"
	world["training_first"] = false
	world["region"] = "asia"
	_left.show_world_status(world)
	_center.show_world_map(entries, "tokyo", world)
	_center.world_map_view().finish_zoom()
	_right.show_world_city(tokyo, world)
	await _capture("world-map-hard.png")
	# Open on Tokyo: halfway in, then there.
	var view := _center.world_map_view()
	_center.zoom_world_to_city("tokyo")
	view._process(WorldMapView.CITY_ZOOM_SECONDS * 0.4)
	await _capture("world-map-city-zooming.png")
	view.finish_zoom()
	await _capture("world-map-city-zoom.png")
	world["region"] = "south_america"
	world["filter"] = "all"
	_left.show_world_status(world)
	_center.show_world_map(entries, "sao_paulo", world)
	_center.world_map_view().finish_zoom()
	_right.show_world_city(_entry(entries, "sao_paulo"), world)
	await _capture("world-map-safe-card.png")
	# Tokyo's section, fresh and then with one seal.
	var city := _city(tokyo, [])
	_left.show_operations_status(city)
	_center.show_operations_map(city)
	_right.show_district_detail(city)
	await _capture("city-operations.png")
	var first := String(city["selected_id"])
	var sealed_city := _city(tokyo, [first])
	_with_best(sealed_city, 268.0, 9860)
	_left.show_operations_status(sealed_city)
	_center.show_operations_map(sealed_city)
	_right.show_district_detail(sealed_city)
	await _capture("city-operations-sealed.png")
	# A threatened city with Assist on.
	var easy := _city(home, [], true)
	_left.show_operations_status(easy)
	_center.show_operations_map(easy)
	_right.show_district_detail(easy)
	await _capture("city-operations-assist.png")
	# A Maw district's card at Full Resonance: it reads the same at every tier.
	var maw := _maw_city(entries)
	if not maw.is_empty():
		_left.show_operations_status(maw)
		_center.show_operations_map(maw)
		_right.show_district_detail(maw)
		await _capture("city-operations-maw.png")
	# Results after the first seal are the city map: the next district picked, Deploy leading.
	var after_seal := _city(tokyo, [first])
	_with_best(after_seal, 241.0, 12400)
	var report := {
		"outcome": &"victory", "score": 9860, "debrief": "Chen: %s is shut. Pick the next district when you are ready." % city["node"]["name"],
		"seconds": 287.0, "previous_best": 0.0, "best_seconds": 287.0, "tier": city["tier"],
		"world": {
			"entry": tokyo, "section": city["section"], "sealed_before": [], "sealed_after": [first], "node": city["node"],
			"kind_label": city["kind_label"], "moved": true, "operation_complete": false, "liberation_before": tokyo["liberation"], "liberation_after": tokyo["liberation"],
		},
		"city": after_seal,
		"picked": false,
		"offer_training": false,
	}
	_with_medals(report, String(city["node"]["kind"]), 0, 0)
	_show_world_results(report)
	await _capture("world-results.png")
	# A defeat: Retry leads, the open districts still pressable.
	report["outcome"] = &"defeat"
	report["score"] = 3120
	report["stats"] = _stats(&"defeat")
	report["medal"] = ""
	report["debrief"] = "Chen: The failsafe fired. %s held. Rest, then go back in." % city["node"]["name"]
	report["offer_training"] = true
	report["world"]["sealed_after"] = []
	report["world"]["moved"] = false
	report["city"] = _city(tokyo, [], false, first)
	report["picked"] = false
	_show_world_results(report)
	await _capture("world-results-defeat.png")
	# Another start district picked after the defeat: its card and Deploy replace Retry.
	var starts: Array = city["section"]["starts"]
	if starts.size() > 1:
		report["city"] = _city(tokyo, [], false, String(starts[starts.size() - 1]))
		report["picked"] = true
		_show_world_results(report)
		await _capture("world-results-picked.png")
	# The third seal: the operation is complete and the next section is open.
	var next_city := _city(tokyo, [], false, "", int(tokyo.get("section", 0)) + 1)
	report = {
		"outcome": &"victory", "score": 11240, "debrief": "Chen: %s is shut. Pick the next district when you are ready." % city["node"]["name"],
		"seconds": 262.0, "previous_best": 287.0, "best_seconds": 262.0, "tier": city["tier"],
		"world": {
			"entry": tokyo, "section": city["section"], "sealed_before": [], "sealed_after": [], "node": city["node"],
			"kind_label": city["kind_label"], "moved": true, "operation_complete": true, "liberation_before": tokyo["liberation"], "liberation_after": int(tokyo["liberation"]) + 4,
		},
		"city": next_city,
		"picked": false,
		"offer_training": false,
	}
	_with_medals(report, String(city["node"]["kind"]), 9860, 11240)
	_show_world_results(report)
	await _capture("world-results-operation.png")
	profile.free()

## A world report's stats and medals, as GameFlowController._with_medals adds them, for a district
## of this kind whose best score was `previous` before the round (0 for none).
func _with_medals(report: Dictionary, kind: String, previous: int, best: int) -> void:
	var thresholds := MissionMedals.world_thresholds(kind, String(report["tier"]))
	var score := int(report["score"])
	report["stats"] = _stats(report["outcome"])
	report["medal"] = MissionMedals.medal_for(score, thresholds) if report["outcome"] == &"victory" else ""
	report["previous_best_score"] = previous
	report["best_score"] = maxi(best, score)
	report["best_medal"] = MissionMedals.medal_for(maxi(best, score), thresholds)

## A district card with a best time and score at its tier, and the medal the score earned.
func _with_best(city: Dictionary, seconds: float, score: int) -> void:
	city["best_seconds"] = seconds
	city["best_score"] = score
	city["medal"] = MissionMedals.medal_for(score, MissionMedals.world_thresholds(String(city["node"].get("kind", WorldMap.KIND_SINGLE)), String(city["tier"])))

func _show_world_results(report: Dictionary) -> void:
	_left.show_world_report(report)
	_center.show_world_results_map(report)
	_right.show_world_results_actions(report)

## The first Maw district in an overrun city's early sections, as a picked city card.
func _maw_city(entries: Array[Dictionary]) -> Dictionary:
	for entry in entries:
		if entry.get("state", "") != WorldMap.STATE_OVERRUN:
			continue
		for index in 4:
			for node in WorldMap.section(String(entry["id"]), index)["nodes"]:
				if node["kind"] == WorldMap.KIND_MAW:
					var shown := entry.duplicate()
					shown["section"] = index
					return _city(shown, [], false, String(node["id"]), index)
	return {}

func _entry(entries: Array[Dictionary], city_id: String) -> Dictionary:
	for entry in entries:
		if entry.get("id", "") == city_id:
			return entry
	return {}

## The shape GameFlowController._city_status builds, with `selected` or the first open district
## picked, in the entry's section or in `section_index`.
func _city(entry: Dictionary, sealed: Array, assist: bool = false, selected: String = "", section_index: int = -1) -> Dictionary:
	var index := section_index if section_index >= 0 else int(entry.get("section", 0))
	var section := WorldMap.section(String(entry["id"]), index)
	var open := WorldMap.available_nodes(section, sealed)
	if selected == "":
		selected = String(open[0]) if not open.is_empty() else ""
	var node := WorldMap.node_in(section, selected)
	var tier := WorldMap.tier_for(String(entry.get("state", "")), assist)
	var kind := String(node.get("kind", WorldMap.KIND_SINGLE))
	var mission := WorldMap.build_mission(entry, index, node, tier)
	return {
		"entry": entry, "section": section, "sealed": sealed, "selected_id": node.get("id", ""), "tier": tier, "assist": assist,
		"node": node, "status": WorldMap.node_status(section, sealed, String(node.get("id", ""))),
		"kind_label": WorldMap.kind_label(kind), "kind_summary": WorldMap.kind_summary(kind),
		"expected_minutes": DifficultyTier.apply_mission(mission, tier).get("expected_minutes", []), "best_seconds": 0.0,
	}

func _capture_tutorial() -> void:
	_menu.show_training_complete(MissionCatalog.deploy_detail(null))
	await _capture("training-complete.png")
	_menu.show_pause(true)
	await _capture("training-pause.png")

func _capture_settings() -> void:
	_menu.show_settings("75%", "50%", "100%", false, false)
	await _capture("settings.png")
	_menu.show_settings("75%", "50%", "100%", false, false, true)
	await _capture("settings-own-music.png")

func _capture_pause() -> void:
	_menu.show_pause()
	await _capture("pause.png")

func _capture(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://reports/menu-states/%s" % file_name))
