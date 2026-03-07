tool
extends EditorPlugin

func _enter_tree():
	# Optional: auto-add autoload named "Chronos"
	# If it already exists, Godot ignores duplicates.
	add_autoload_singleton("Chronos", "res://addons/chronos/Chronos.gd")

func _exit_tree():
	# Keep it simple for MVP: do NOT remove autoload on disable (safer for beginners)
	pass
