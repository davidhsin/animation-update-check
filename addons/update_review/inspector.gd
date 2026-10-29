@tool
extends EditorInspectorPlugin

const Audit = preload("audit.gd")

func _can_handle(object: Object) -> bool:
	return object is AnimationPlayer

func _parse_begin(object: Object) -> void:
	var player = object as AnimationPlayer
	var box = VBoxContainer.new()
	box.name = "AnimationUpdateCheckPanel"
	var heading = Label.new()
	heading.text = "Animation Update Check · 0.2 Beta"
	box.add_child(heading)
	var instruction = Label.new()
	instruction.text = "Compare proposed SpriteFrames with existing frame tracks. Global library only. Review hints in your game."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(instruction)
	var targets: Array[AnimatedSprite2D] = []
	var scene = EditorInterface.get_edited_scene_root()
	if scene != null:
		_collect_targets(scene, targets)
	var selector = OptionButton.new()
	for target in targets:
		selector.add_item(str(scene.get_path_to(target)))
	box.add_child(selector)
	var resource_label = Label.new()
	resource_label.text = "Proposed SpriteFrames (.tres):"
	box.add_child(resource_label)
	var picker = EditorResourcePicker.new()
	picker.name = "ProposedFramesPicker"
	picker.base_type = "SpriteFrames"
	box.add_child(picker)
	var compatibility = CheckBox.new()
	compatibility.name = "AS2PCompatibility"
	compatibility.text = "Tested AS2P compatibility checks"
	compatibility.tooltip_text = "Optional checks for AS2P commit " + Audit.AS2P_REVISION + ". Leave off for other converters."
	box.add_child(compatibility)
	var report = TextEdit.new()
	report.name = "UpdateCheckReport"
	report.editable = false
	report.custom_minimum_size.y = 400
	report.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	report.placeholder_text = "No check has run. Drop a SpriteFrames resource above."
	var button = Button.new()
	button.name = "RunUpdateCheck"
	button.text = "Check proposed update"
	button.disabled = targets.is_empty()
	button.pressed.connect(func():
		if not is_instance_valid(player) or selector.selected < 0 or selector.selected >= targets.size() or not is_instance_valid(targets[selector.selected]):
			report.text = "Scene selection changed. Reselect the AnimationPlayer and try again."
			return
		var result = Audit.new().inspect(picker.edited_resource as SpriteFrames, player, targets[selector.selected], compatibility.button_pressed)
		report.set_meta("last_report", result)
		var lines: Array[String] = ["%d review hints" % result.issues.size(), ""]
		if result.issues.is_empty():
			lines.append("No listed risks detected. This does not certify the animation or its gameplay timing.")
		var labels = {"KEY_AFTER_PROPOSED_END": "Key past the new end", "FRAME_INDEX_AT_KEY_CHANGES": "Timing needs review", "AS2P_TRACK_ORDER": "Converter track-order risk", "AS2P_PARTIAL_TRACKS": "Incomplete generated tracks", "NAME_COLLISION": "Conflicting names"}
		for issue in result.issues:
			lines.append("%s · %s\n%s\n" % [issue.animation, labels.get(issue.code, issue.code), issue.message])
		lines.append("PROPOSED ANIMATIONS")
		for row in result.animations:
			lines.append("%s: %d frames, %.3f s; frame keys change: %s; loop changes: %s" % [row.source, row.frame_count, row.proposed_length, str(row.frame_keys_change), str(row.loop_changes)])
		report.text = "\n".join(lines)
	)
	box.add_child(button)
	box.add_child(report)
	var open_button = Button.new()
	open_button.name = "OpenUpdateReport"
	open_button.text = "Open readable report"
	open_button.pressed.connect(func(): _open_report(report.text))
	box.add_child(open_button)
	var copy_button = Button.new()
	copy_button.text = "Copy report JSON"
	copy_button.tooltip_text = "Copies the last report to your clipboard when clicked."
	copy_button.pressed.connect(func():
		if report.has_meta("last_report"):
			DisplayServer.clipboard_set(JSON.stringify(report.get_meta("last_report"), "\t", true))
	)
	box.add_child(copy_button)
	var invalidate = func(_value):
		report.text = "Inputs changed. Run a new check."
		if report.has_meta("last_report"):
			report.remove_meta("last_report")
	picker.resource_changed.connect(invalidate)
	selector.item_selected.connect(invalidate)
	compatibility.toggled.connect(invalidate)
	add_custom_control(box)

func _open_report(text: String) -> void:
	var window = Window.new()
	window.name = "UpdateReviewWindow"
	window.title = "Animation Update Check - Review"
	window.size = Vector2i(900, 760)
	window.min_size = Vector2i(700, 550)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	window.add_child(margin)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title = Label.new()
	title.text = "Animation Update Check"
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	var scope = Label.new()
	scope.text = "0.2 Beta | Global library | Snapshot report, no automatic changes"
	scope.add_theme_font_size_override("font_size", 16)
	content.add_child(scope)
	var output = TextEdit.new()
	output.text = text
	output.editable = false
	output.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.add_theme_font_size_override("font_size", 18)
	content.add_child(output)
	var close_button = Button.new()
	close_button.text = "Close report"
	close_button.pressed.connect(window.queue_free)
	content.add_child(close_button)
	window.close_requested.connect(window.queue_free)
	EditorInterface.get_base_control().add_child(window)
	window.popup_centered()

func _collect_targets(node: Node, targets: Array[AnimatedSprite2D]) -> void:
	if node is AnimatedSprite2D:
		targets.append(node)
	for child in node.get_children():
		_collect_targets(child, targets)
