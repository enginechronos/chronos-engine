extends Node

func _ready() -> void:
	print("SETUP: running chronos_setup.gd")

	Chronos.configure(
		"https://chronos-magic-engine-live.vercel.app",                 # use site url here
		"CHRONOS_ ",                                                    # keep your real api key here
		"ghost_village_test",                                           # your world id
		"guard_1"                                                       # your npc id
	)

	Chronos.start()

	Chronos.request_ok.connect(_on_ok)
	Chronos.request_err.connect(_on_err)

	print("SETUP: Chronos configured + started")

func _on_ok(tag: String, _data: Variant) -> void:
	print("[Chronos OK]", tag)

func _on_err(tag: String, code: int, message: String, _raw: Variant) -> void:
	print("[Chronos ERR]", tag, code, message)
