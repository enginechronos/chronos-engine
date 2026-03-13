extends Node


func _ready() -> void:
	print("SETUP: running chronos_setup.gd")

	Chronos.configure(
		"https://chronos-magic-engine-live.vercel.app",
		"CHRONOS_xxxxx",
		"reputation_xxx",
		"guard_xxx"
	)

	Chronos.configure_runtime(true, 2, 50)

	if Chronos.status.is_connected(_on_status):
		Chronos.status.disconnect(_on_status)
	if Chronos.request_ok.is_connected(_on_ok):
		Chronos.request_ok.disconnect(_on_ok)
	if Chronos.request_err.is_connected(_on_err):
		Chronos.request_err.disconnect(_on_err)

	Chronos.status.connect(_on_status)
	Chronos.request_ok.connect(_on_ok)
	Chronos.request_err.connect(_on_err)

	Chronos.start()
	print("SETUP: Chronos configured + started")


func _on_status(msg: String) -> void:
	print("[Chronos STATUS]", msg)


func _on_ok(_tag: String, _data: Variant) -> void:
	pass


func _on_err(_tag: String, _code: int, _message: String, _raw: Variant) -> void:
	pass
