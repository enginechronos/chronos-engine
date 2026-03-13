extends Node

signal status(msg: String)
signal world_event_appended(evt: Dictionary)
signal npc_state_updated(row: Dictionary)
signal request_ok(tag: String, data: Variant)
signal request_err(tag: String, code: int, message: String, raw: Variant)

const Types = preload("res://addons/chronos/ChronosTypes.gd")
const RestClientScript = preload("res://addons/chronos/ChronosRESTClient.gd")
const SSEClientScript = preload("res://addons/chronos/ChronosSSEClient.gd")

var base_url: String = ""
var api_key: String = ""
var world_id: String = ""
var npc_id: String = ""

var _rest = null
var _sse = null

var auto_brain_enabled: bool = true
var auto_brain_min_interval_sec: int = 2
var auto_brain_max_events: int = 50

var _append_meta_q: Array = []
var _last_brain_unix: int = 0
var _started: bool = false
var _configured: bool = false


func _ready() -> void:
	if _rest == null:
		_rest = RestClientScript.new()
		add_child(_rest)

	if _sse == null:
		_sse = SSEClientScript.new()
		add_child(_sse)

	if not _rest.request_ok.is_connected(_on_rest_ok):
		_rest.request_ok.connect(_on_rest_ok)
	if not _rest.request_err.is_connected(_on_rest_err):
		_rest.request_err.connect(_on_rest_err)

	if not _sse.stream_status.is_connected(_on_sse_status):
		_sse.stream_status.connect(_on_sse_status)
	if not _sse.world_event_appended.is_connected(_on_sse_world_event):
		_sse.world_event_appended.connect(_on_sse_world_event)
	if not _sse.npc_state_updated.is_connected(_on_sse_npc_state):
		_sse.npc_state_updated.connect(_on_sse_npc_state)


func configure(_base_url: String, _api_key: String, _world_id: String, _npc_id: String = "guard_1") -> void:
	base_url = _base_url.strip_edges()
	if base_url != "" and not (base_url.begins_with("http://") or base_url.begins_with("https://")):
		base_url = "https://" + base_url

	api_key = _api_key.strip_edges()
	world_id = _world_id.strip_edges()
	npc_id = _npc_id.strip_edges()

	_rest.base_url = base_url
	_rest.api_key = api_key
	_sse.base_url = base_url
	_sse.api_key = api_key
	_sse.world_id = world_id

	_configured = true
	status.emit("Chronos configured")


func configure_runtime(_auto_brain_enabled: bool = true, _auto_brain_min_interval_sec: int = 2, _auto_brain_max_events: int = 50) -> void:
	auto_brain_enabled = _auto_brain_enabled
	auto_brain_min_interval_sec = maxi(0, _auto_brain_min_interval_sec)
	auto_brain_max_events = clampi(_auto_brain_max_events, 5, 200)
	status.emit("Chronos runtime configured auto_brain=" + str(auto_brain_enabled))


func start() -> void:
	if not _configured:
		status.emit("Chronos missing config. Call Chronos.configure() first.")
		return

	if _started:
		status.emit("Chronos SSE already running")
		return

	if base_url == "" or api_key == "" or world_id == "":
		status.emit("Chronos missing config (base_url/api_key/world_id)")
		return

	_started = true
	_sse.start()
	status.emit("Chronos SSE started")


func stop() -> void:
	if not _started:
		return

	_started = false
	_sse.stop()


func restart() -> void:
	stop()
	start()


func append_event(entity_id: String, event_type: String, payload: Dictionary, significant: bool = true, auto_brain_override: int = -1) -> void:
	var should_auto: bool = auto_brain_enabled
	if auto_brain_override == 0:
		should_auto = false
	elif auto_brain_override == 1:
		should_auto = true

	_append_meta_q.append({
		"significant": significant,
		"auto_brain": should_auto,
		"event_type": event_type
	})

	_rest.post_json("events.append", "/api/events/append", {
		"world_id": world_id,
		"entity_id": entity_id,
		"event_type": event_type,
		"payload": payload,
		"significant": significant
	})


func brain_think(max_events: int = 50) -> void:
	_rest.post_json("brain.think", "/api/brain/think", {
		"world_id": world_id,
		"npc_id": npc_id,
		"max_events": clampi(max_events, 5, 200)
	})


func get_npc_state(which_npc_id: String = "") -> void:
	var id: String = which_npc_id if which_npc_id != "" else npc_id
	var path: String = "/api/npc/state?world_id=" + Types.url_encode(world_id) + "&npc_id=" + Types.url_encode(id)
	_rest.get_json("npc.state", path)


func set_rules(rules_text: String) -> void:
	_rest.post_json("rules.set", "/api/rules/set", {
		"world_id": world_id,
		"rules_text": rules_text
	})


func get_rules() -> void:
	var path: String = "/api/rules/get?world_id=" + Types.url_encode(world_id)
	_rest.get_json("rules.get", path)


func _try_auto_brain_from_append(meta: Dictionary) -> void:
	if not meta.get("auto_brain", false):
		return
	if not meta.get("significant", false):
		return

	var now: int = int(Time.get_unix_time_from_system())
	if now < _last_brain_unix + auto_brain_min_interval_sec:
		return

	_last_brain_unix = now
	brain_think(auto_brain_max_events)


func _on_rest_ok(tag: String, data: Variant) -> void:
	request_ok.emit(tag, data)

	if tag == "events.append":
		if _append_meta_q.size() > 0:
			var meta: Dictionary = _append_meta_q.pop_front()
			_try_auto_brain_from_append(meta)
		return

	if tag == "npc.state" and data is Dictionary and data.has("npc_id") and data.has("state"):
		npc_state_updated.emit({
			"world_id": data.get("world_id", world_id),
			"npc_id": data["npc_id"],
			"state": data["state"],
			"updated_at": data.get("updated_at", Types.iso_now())
		})
		return

	if tag == "brain.think":
		get_npc_state(npc_id)
		return


func _on_rest_err(tag: String, code: int, message: String, raw: Variant) -> void:
	if tag == "events.append" and _append_meta_q.size() > 0:
		_append_meta_q.pop_front()

	request_err.emit(tag, code, message, raw)
	status.emit("Chronos request error [" + tag + "] " + str(code) + ": " + message)


func _on_sse_status(msg: String) -> void:
	status.emit(msg)


func _on_sse_world_event(evt: Dictionary) -> void:
	world_event_appended.emit(evt)


func _on_sse_npc_state(row: Dictionary) -> void:
	npc_state_updated.emit(row)
