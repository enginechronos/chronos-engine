extends Node

func _ready():
	print("SETUP: running chronos_setup.gd")

	Chronos.configure(
		"https://chronos-magic-engine-live.vercel.app",                 # use site url here
		"CHRONOS_ ",                                                    # keep your real api key here
		"ghost_village_test",                                           # your world id
		"guard_1"                                                       # your npc id
	)

	Chronos.start()

	Chronos.connect("request_ok", self, "_on_ok")
	Chronos.connect("request_err", self, "_on_err")

	print("SETUP: Chronos configured + started")

func _on_ok(tag, _data):
	print("[Chronos OK]", tag)

func _on_err(tag, code, message, _raw):
	print("[Chronos ERR]", tag, code, message)
