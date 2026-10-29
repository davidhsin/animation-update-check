@tool
extends EditorPlugin

var inspector: EditorInspectorPlugin

func _enter_tree() -> void:
	inspector = preload("inspector.gd").new()
	add_inspector_plugin(inspector)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector)
	inspector = null
