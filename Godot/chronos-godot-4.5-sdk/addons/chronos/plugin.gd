@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("Chronos", "res://addons/chronos/Chronos.gd")

func _exit_tree() -> void:
	pass
