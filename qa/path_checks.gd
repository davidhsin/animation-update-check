extends SceneTree

const Audit = preload("res://addons/update_review/audit.gd")
var cases: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_case("explicit_current_directory", func(f): _paths(f, "./Sprite"), _shortening_detected)
	_case("unique_node_name", func(f): _paths(f, "%Sprite"), _shortening_detected)
	_case("absolute_node_path", func(f): _paths(f, str(f.sprite.get_path())), _shortening_detected)
	_case("root_is_sprite", func(f):
		f.player.root_node = f.player.get_path_to(f.sprite)
		_paths(f, ".")
	, _shortening_detected)
	_case("property_only_at_root", func(f):
		f.player.root_node = f.player.get_path_to(f.sprite)
		_paths(f, "")
	, _shortening_detected)
	_case("alias_duplicate_tracks", func(f):
		var animation: Animation = f.player.get_animation("attack")
		var index = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(index, NodePath("%Sprite:frame"))
		animation.value_track_set_update_mode(index, Animation.UPDATE_DISCRETE)
		animation.track_insert_key(index, 0, 0)
	, func(report): return _has(report, "DUPLICATE_TARGET_TRACKS") and not _has(report, "FRAME_INDEX_AT_KEY_CHANGES"))
	_case("other_unique_target", func(f):
		var other = AnimatedSprite2D.new()
		other.name = "OtherSprite"
		f.scene.add_child(other)
		other.owner = f.scene
		other.unique_name_in_owner = true
		_paths(f, "%OtherSprite")
	, func(report): return _has(report, "NAME_USED_BY_OTHER_TARGET") and not _has(report, "KEY_AFTER_PROPOSED_END"))
	_case("nested_property_is_not_frame", func(f):
		var animation: Animation = f.player.get_animation("attack")
		animation.track_set_path(0, NodePath("Sprite:sprite_frames:frame"))
		animation.track_set_path(1, NodePath("Sprite:sprite_frames:animation"))
	, func(report): return _has(report, "NAME_USED_BY_OTHER_TARGET"))
	var passed = cases.all(func(value): return value.passed)
	var output = {"case_count": cases.size(), "all_passed": passed, "engine": Engine.get_version_info(), "cases": cases}
	var file = FileAccess.open(OS.get_environment("PATH_QA_OUTPUT"), FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t", true))
	print("PATH_QA ", JSON.stringify({"case_count": cases.size(), "all_passed": passed}))
	quit(0 if passed else 1)

func _case(case_name: String, setup: Callable, predicate: Callable) -> void:
	var packed: PackedScene = ResourceLoader.load("res://demo.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	var scene = packed.duplicate(true).instantiate()
	root.add_child(scene)
	var sprite: AnimatedSprite2D = scene.get_node("Sprite")
	sprite.unique_name_in_owner = true
	var proposed = sprite.sprite_frames.duplicate(true)
	proposed.remove_frame("attack", 3)
	proposed.remove_frame("attack", 2)
	var fixture = {"scene": scene, "player": scene.get_node("AnimationPlayer"), "sprite": sprite, "proposed": proposed}
	setup.call(fixture)
	var before = _fingerprint(fixture)
	var report = Audit.new().inspect(proposed, fixture.player, sprite)
	var unchanged = before == _fingerprint(fixture)
	var passed: bool = predicate.call(report) and unchanged
	cases.append({"name": case_name, "passed": passed, "resources_unchanged": unchanged, "report": report})
	print(case_name, ": ", "PASS" if passed else "FAIL")
	scene.free()

func _fingerprint(f: Dictionary) -> String:
	var values = []
	for name in f.player.get_animation_list():
		var animation: Animation = f.player.get_animation(name)
		values.append(var_to_str(animation.get_property_list()))
		for property in animation.get_property_list():
			if property.usage & PROPERTY_USAGE_STORAGE:
				values.append([property.name, var_to_str(animation.get(property.name))])
	for frames in [f.proposed, f.sprite.sprite_frames]:
		values.append(var_to_str(frames.get("animations")))
	return var_to_str(values)

func _paths(f: Dictionary, node_path: String) -> void:
	for name in f.player.get_animation_list():
		var animation: Animation = f.player.get_animation(name)
		animation.track_set_path(0, NodePath(node_path + ":frame"))
		animation.track_set_path(1, NodePath(node_path + ":animation"))
		if f.player.get_node(f.player.root_node) == f.sprite:
			for i in range(2, animation.get_track_count()):
				animation.track_set_path(i, NodePath("../" + str(animation.track_get_path(i))))

func _has(report: Dictionary, code: String) -> bool:
	return report.issues.any(func(issue): return issue.code == code)

func _shortening_detected(report: Dictionary) -> bool:
	return report.issues.filter(func(issue): return issue.code == "KEY_AFTER_PROPOSED_END").size() == 2 and not _has(report, "NAME_USED_BY_OTHER_TARGET")
