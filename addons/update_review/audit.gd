@tool
extends RefCounted

const EPSILON = 0.000001
const AS2P_REVISION = "e9a20caefceb0ff742551da8ccf55f962917e210"

# Read resources only: no imports, resource writes, or automatic retiming.
func inspect(proposed: SpriteFrames, player: AnimationPlayer, target: AnimatedSprite2D, check_as2p := false) -> Dictionary:
	var result = {"version": "0.2.1", "scope": "Global library; discrete forward frame tracks; frame indices, not artwork identity", "as2p_checks": check_as2p, "issues": [], "animations": []}
	if not is_instance_valid(proposed) or not is_instance_valid(player) or not is_instance_valid(target):
		_issue(result, "INPUT_REQUIRED", "", "Select proposed SpriteFrames, an AnimationPlayer and an AnimatedSprite2D.")
		return result
	if proposed.get_animation_names().is_empty():
		_issue(result, "NO_ANIMATIONS", "", "The proposed SpriteFrames resource contains no animations.")
		return result
	if not player.is_inside_tree() or not target.is_inside_tree():
		_issue(result, "UNATTACHED_INPUT", "", "Open the scene before checking its animation nodes.")
		return result
	var animation_root = player.get_node_or_null(player.root_node)
	if animation_root == null or animation_root.get_tree() != target.get_tree():
		_issue(result, "INVALID_ROOT", "", "The AnimationPlayer root and selected sprite must resolve in the same scene tree.")
		return result
	if not player.has_animation_library("") and player.get_animation_library_list().size() > 0:
		_issue(result, "NAMED_LIBRARY_UNSUPPORTED", "", "This beta checks the global library only. The player currently uses named libraries.")
		return result
	var mapped_names = {}
	for source_name in proposed.get_animation_names():
		var mapped = str(source_name)
		if check_as2p:
			mapped = mapped.replace(":", "_").replace("[", "_")
		if mapped_names.has(mapped):
			_issue(result, "NAME_COLLISION", mapped, "Names '%s' and '%s' map to the same animation name." % [mapped_names[mapped], source_name])
		mapped_names[mapped] = str(source_name)
		if mapped.is_empty() or ["/", ":", ",", "["].any(func(token): return mapped.contains(token)):
			_issue(result, "UNSUPPORTED_NAME", str(source_name), "Use a nonempty global animation name without / : , [ (or opt into the tested AS2P naming rules).")
			continue
		var timing = _timing(proposed, source_name)
		if timing.is_empty():
			_issue(result, "INVALID_TIMING", str(source_name), "At least one frame and a finite positive frame rate/duration are required.")
			continue
		var proposed_loop = Animation.LOOP_LINEAR if proposed.get_animation_loop(source_name) else Animation.LOOP_NONE
		var row = {"source": str(source_name), "target": mapped, "proposed_length": timing.length, "frame_count": timing.keys.size(), "existing": false, "frame_keys_change": true, "loop_changes": false}
		if not player.has_animation_library("") or not player.get_animation_library("").has_animation(mapped):
			result.animations.append(row)
			continue
		row.existing = true
		var current: Animation = player.get_animation_library("").get_animation(mapped)
		row["current_length"] = current.length
		row.loop_changes = current.loop_mode != proposed_loop
		var frame_indices = _tracks(current, animation_root, target, &"frame")
		var animation_indices = _tracks(current, animation_root, target, &"animation")
		if frame_indices.is_empty() and animation_indices.is_empty():
			_issue(result, "NAME_USED_BY_OTHER_TARGET", mapped, "An existing animation has this name but no matching tracks for the selected sprite. Timing comparison was skipped.")
			result.animations.append(row)
			continue
		var frame_index = -1 if frame_indices.is_empty() else frame_indices[0]
		var animation_index = -1 if animation_indices.is_empty() else animation_indices[0]
		var can_compare_frames = frame_index >= 0
		if frame_indices.size() > 1 or animation_indices.size() > 1:
			_issue(result, "DUPLICATE_TARGET_TRACKS", mapped, "Multiple frame or animation tracks target this sprite. Frame-index comparison was skipped.")
			can_compare_frames = false
		if frame_index >= 0:
			if not current.track_is_enabled(frame_index) or current.value_track_get_update_mode(frame_index) != Animation.UPDATE_DISCRETE or not _valid_frame_keys(current, frame_index):
				_issue(result, "UNSUPPORTED_FRAME_TRACK", mapped, "Frame comparison requires an enabled discrete track with nonnegative integer frame keys.")
				can_compare_frames = false
		if animation_index >= 0 and (not current.track_is_enabled(animation_index) or current.track_get_key_count(animation_index) != 1 or current.track_get_key_time(animation_index, 0) > EPSILON or str(current.track_get_key_value(animation_index, 0)) != str(source_name)):
			_issue(result, "ANIMATION_BINDING_REVIEW", mapped, "The existing animation binding is disabled, changes over time, or selects a different SpriteFrames animation. Frame-index comparison was skipped.")
			can_compare_frames = false
		row.frame_keys_change = not _keys_equal(current, frame_index, timing.keys)
		if check_as2p and frame_index >= 0 and animation_index >= 0 and frame_index > animation_index:
			_issue(result, "AS2P_TRACK_ORDER", mapped, "The tested AS2P revision can delete the wrong track with this ordering. This warning does not describe every converter version.")
		if check_as2p and (frame_index < 0) != (animation_index < 0):
			_issue(result, "AS2P_PARTIAL_TRACKS", mapped, "Only one generated track exists. The tested AS2P revision may leave duplicate frame tracks or report an index error.")
		for track_index in current.get_track_count():
			if track_index in frame_indices or track_index in animation_indices or not current.track_is_enabled(track_index):
				continue
			var track_path = str(current.track_get_path(track_index))
			var outside: Array[String] = []
			var shifts: Array[String] = []
			for key_index in current.track_get_key_count(track_index):
				var time = current.track_get_key_time(track_index, key_index)
				if time > timing.length + EPSILON:
					outside.append("%.3f" % time)
				elif can_compare_frames and _old_frame(current, frame_index, time) != _new_frame(timing.keys, time):
					shifts.append("%.3f" % time)
			if not outside.is_empty():
				_issue(result, "KEY_AFTER_PROPOSED_END", mapped, "%s: keys at %s s fall after the proposed %.3f s end." % [track_path, ", ".join(outside), timing.length])
			if not shifts.is_empty():
				_issue(result, "FRAME_INDEX_AT_KEY_CHANGES", mapped, "%s: frame indices at %s s change. Review timing in the game; no automatic retiming is proposed." % [track_path, ", ".join(shifts)])
		result.animations.append(row)
	return result

func _tracks(animation: Animation, animation_root: Node, target: AnimatedSprite2D, property: StringName) -> Array[int]:
	var indices: Array[int] = []
	for i in animation.get_track_count():
		if animation.track_get_type(i) != Animation.TYPE_VALUE:
			continue
		var path = animation.track_get_path(i)
		if path.get_subname_count() != 1 or path.get_subname(0) != property:
			continue
		# Compare resolved nodes, so aliases such as %Sprite and ./Sprite are equivalent.
		var names = str(path.get_concatenated_names())
		if path.is_absolute() and not names.begins_with("/"):
			names = "/" + names
		var node_path = NodePath(names)
		var resolved = animation_root if path.get_name_count() == 0 else animation_root.get_node_or_null(node_path)
		if resolved == target:
			indices.append(i)
	return indices

func _valid_frame_keys(animation: Animation, track: int) -> bool:
	if animation.track_get_key_count(track) == 0:
		return false
	for i in animation.track_get_key_count(track):
		var value = animation.track_get_key_value(track, i)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or abs(float(value) - round(float(value))) > EPSILON:
			return false
	return true

func _timing(frames: SpriteFrames, name: StringName) -> Dictionary:
	var fps = frames.get_animation_speed(name)
	if not is_finite(fps) or fps <= 0 or frames.get_frame_count(name) == 0:
		return {}
	var keys: Array = []
	var time := 0.0
	for i in frames.get_frame_count(name):
		var duration = frames.get_frame_duration(name, i)
		if not is_finite(duration) or duration <= 0:
			return {}
		keys.append({"time": time, "frame": i})
		time += duration / fps
	if not is_finite(time):
		return {}
	return {"keys": keys, "length": time}

func _old_frame(animation: Animation, track: int, time: float) -> int:
	var lo := 0
	var hi = animation.track_get_key_count(track)
	while lo < hi:
		var mid: int = (lo + hi) >> 1
		if animation.track_get_key_time(track, mid) <= time + EPSILON:
			lo = mid + 1
		else:
			hi = mid
	return -1 if lo == 0 else int(animation.track_get_key_value(track, lo - 1))

func _new_frame(keys: Array, time: float) -> int:
	var lo := 0
	var hi = keys.size()
	while lo < hi:
		var mid: int = (lo + hi) >> 1
		if keys[mid].time <= time + EPSILON:
			lo = mid + 1
		else:
			hi = mid
	return -1 if lo == 0 else int(keys[lo - 1].frame)

func _keys_equal(animation: Animation, track: int, keys: Array) -> bool:
	if track < 0 or not _valid_frame_keys(animation, track) or animation.track_get_key_count(track) != keys.size():
		return false
	for i in keys.size():
		if abs(animation.track_get_key_time(track, i) - keys[i].time) > EPSILON or int(animation.track_get_key_value(track, i)) != keys[i].frame:
			return false
	return true

func _issue(result: Dictionary, code: String, animation: String, message: String) -> void:
	result.issues.append({"code": code, "animation": animation, "message": message})
