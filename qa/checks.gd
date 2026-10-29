extends SceneTree

const Audit = preload("res://addons/update_review/audit.gd")
var cases: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _fixture() -> Dictionary:
	var packed: PackedScene = ResourceLoader.load("res://demo.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	var scene = packed.duplicate(true).instantiate()
	root.add_child(scene)
	var sprite: AnimatedSprite2D = scene.get_node("Sprite")
	return {"scene": scene, "player": scene.get_node("AnimationPlayer"), "sprite": sprite, "proposed": sprite.sprite_frames.duplicate(true)}

func _run() -> void:
	_case("unchanged", _noop, func(r): return r.issues.is_empty())
	_case("missing_resource", func(f): f.proposed = null, func(r): return _has(r, "INPUT_REQUIRED"))
	_case("missing_player", func(f): f.player = null, func(r): return _has(r, "INPUT_REQUIRED"))
	_case("empty_resource", func(f):
		for n in f.proposed.get_animation_names(): f.proposed.remove_animation(n)
	, func(r): return _has(r, "NO_ANIMATIONS"))
	_case("empty_frames", func(f): f.proposed.clear("attack"), func(r): return _has(r, "INVALID_TIMING"))
	_case("paused_fps", func(f): f.proposed.set_animation_speed("attack", 0), func(r): return _has(r, "INVALID_TIMING"))
	_case("infinite_fps", func(f): f.proposed.set_animation_speed("attack", INF), func(r): return _has(r, "INVALID_TIMING"))
	_case("shortened_events", _shorten, func(r): return r.issues.filter(func(i): return i.code == "KEY_AFTER_PROPOSED_END").size() == 2)
	_case("key_at_exact_end", _shorten, func(r): return not r.issues.any(func(i): return i.code == "KEY_AFTER_PROPOSED_END" and "Hitbox" in i.message))
	_case("lengthened", func(f): f.proposed.add_frame("attack", f.proposed.get_frame_texture("attack", 3)), func(r): return r.issues.is_empty())
	_case("changed_duration", _lengthen_first, func(r): return _has(r, "FRAME_INDEX_AT_KEY_CHANGES") and not _has(r, "KEY_AFTER_PROPOSED_END"))
	_case("disabled_manual_tracks", func(f):
		_shorten(f)
		var a: Animation = f.player.get_animation("attack")
		for i in range(2, a.get_track_count()): a.track_set_enabled(i, false)
	, func(r): return r.issues.is_empty())
	_case("other_sprite_same_name", func(f):
		var a: Animation = f.player.get_animation("attack")
		a.track_set_path(0, NodePath("OtherSprite:frame"))
		a.track_set_path(1, NodePath("OtherSprite:animation"))
		_shorten(f)
	, func(r): return _has(r, "NAME_USED_BY_OTHER_TARGET") and not _has(r, "KEY_AFTER_PROPOSED_END"))
	_case("duplicate_frame_track", func(f):
		var a: Animation = f.player.get_animation("attack")
		var i = a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(i, NodePath("Sprite:frame"))
		a.track_insert_key(i, 0, 0)
		_lengthen_first(f)
	, func(r): return _has(r, "DUPLICATE_TARGET_TRACKS") and not _has(r, "FRAME_INDEX_AT_KEY_CHANGES"))
	_case("continuous_frame_track", func(f):
		f.player.get_animation("attack").value_track_set_update_mode(0, Animation.UPDATE_CONTINUOUS)
		_lengthen_first(f)
	, func(r): return _has(r, "UNSUPPORTED_FRAME_TRACK") and not _has(r, "FRAME_INDEX_AT_KEY_CHANGES"))
	_case("disabled_frame_track", func(f):
		f.player.get_animation("attack").track_set_enabled(0, false)
		_lengthen_first(f)
	, func(r): return _has(r, "UNSUPPORTED_FRAME_TRACK") and not _has(r, "FRAME_INDEX_AT_KEY_CHANGES"))
	_case("noninteger_frame_key", func(f): f.player.get_animation("attack").track_set_key_value(0, 0, 0.5), func(r): return _has(r, "UNSUPPORTED_FRAME_TRACK"))
	_case("different_animation_binding", func(f):
		f.player.get_animation("attack").track_set_key_value(1, 0, "idle")
		_lengthen_first(f)
	, func(r): return _has(r, "ANIMATION_BINDING_REVIEW") and not _has(r, "FRAME_INDEX_AT_KEY_CHANGES"))
	_case("binding_changes_over_time", func(f): f.player.get_animation("attack").track_insert_key(1, 0.2, "idle"), func(r): return _has(r, "ANIMATION_BINDING_REVIEW"))
	_case("generic_mode_no_converter_claim", func(f): f.player.get_animation("attack").track_move_to(1, 0), func(r): return not _has(r, "AS2P_TRACK_ORDER"))
	_case("as2p_reorder_opt_in", func(f): f.player.get_animation("attack").track_move_to(1, 0), func(r): return _has(r, "AS2P_TRACK_ORDER"), true)
	_case("as2p_partial_tracks_opt_in", func(f): f.player.get_animation("attack").remove_track(1), func(r): return _has(r, "AS2P_PARTIAL_TRACKS"), true)
	_case("names_exact_by_default", _colliding_names, func(r): return _has(r, "UNSUPPORTED_NAME") and not _has(r, "NAME_COLLISION"))
	_case("as2p_name_collision_opt_in", _colliding_names, func(r): return _has(r, "NAME_COLLISION"), true)
	_case("named_library_is_reported", func(f):
		var library = f.player.get_animation_library("")
		f.player.remove_animation_library("")
		f.player.add_animation_library("character", library)
	, func(r): return _has(r, "NAMED_LIBRARY_UNSUPPORTED"))
	_case("new_library", func(f): f.player.remove_animation_library(""), func(r): return r.issues.is_empty() and r.animations.all(func(a): return not a.existing))
	_case("loop_change", func(f): f.proposed.set_animation_loop("attack", true), func(r): return r.animations.any(func(a): return a.source == "attack" and a.loop_changes))
	_case("unattached_sprite", func(f): f.scene.remove_child(f.sprite), func(r): return _has(r, "UNATTACHED_INPUT"))
	_case("invalid_animation_root", func(f): f.player.root_node = NodePath("MissingRoot"), func(r): return _has(r, "INVALID_ROOT"))
	var output = {"engine": Engine.get_version_info(), "case_count": cases.size(), "all_passed": cases.all(func(c): return c.passed), "cases": cases}
	var file = FileAccess.open(OS.get_environment("RELEASE_QA_OUTPUT"), FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t", true))
	print("RELEASE_QA ", JSON.stringify({"case_count": cases.size(), "all_passed": output.all_passed}))
	quit(0 if output.all_passed else 1)

func _case(name: String, setup: Callable, predicate: Callable, as2p := false) -> void:
	var f = _fixture()
	setup.call(f)
	var before = _fingerprint(f)
	var started = Time.get_ticks_usec()
	var result = Audit.new().inspect(f.proposed, f.player, f.sprite, as2p)
	var duration = Time.get_ticks_usec() - started
	var unchanged = before == _fingerprint(f)
	var ok: bool = predicate.call(result) and unchanged
	cases.append({"name": name, "passed": ok, "resources_unchanged": unchanged, "elapsed_usec": duration, "report": result})
	print(name, ": ", "PASS" if ok else "FAIL")
	if not f.sprite.is_inside_tree(): f.sprite.free()
	f.scene.free()

func _fingerprint(f: Dictionary) -> String:
	var data = {}
	if is_instance_valid(f.player):
		for name in f.player.get_animation_list():
			var a: Animation = f.player.get_animation(name)
			var tracks: Array = []
			for i in a.get_track_count():
				var keys: Array = []
				for k in a.track_get_key_count(i): keys.append([a.track_get_key_time(i,k), var_to_str(a.track_get_key_value(i,k)), a.track_get_key_transition(i,k)])
				tracks.append([str(a.track_get_path(i)), a.track_get_type(i), a.track_is_enabled(i), keys])
			data[str(name)] = [a.length, a.loop_mode, tracks]
	for key in ["proposed", "sprite"]:
		var frames: SpriteFrames = f.proposed if key == "proposed" else f.sprite.sprite_frames
		var values = {}
		if frames != null:
			for n in frames.get_animation_names():
				var items: Array = []
				for i in frames.get_frame_count(n): items.append([frames.get_frame_duration(n, i), frames.get_frame_texture(n, i).get_instance_id()])
				values[str(n)] = [frames.get_animation_speed(n), frames.get_animation_loop(n), items]
		data[key] = values
	return var_to_str(data)

func _noop(_f: Dictionary) -> void:
	pass

func _shorten(f: Dictionary) -> void:
	f.proposed.remove_frame("attack", 3)
	f.proposed.remove_frame("attack", 2)

func _lengthen_first(f: Dictionary) -> void:
	f.proposed.set_frame("attack", 0, f.proposed.get_frame_texture("attack", 0), 3.0)

func _colliding_names(f: Dictionary) -> void:
	for name in ["walk:a", "walk_a"]:
		f.proposed.add_animation(name)
		f.proposed.add_frame(name, f.proposed.get_frame_texture("attack", 0))

func _has(report: Dictionary, code: String) -> bool:
	return report.issues.any(func(i): return i.code == code)
