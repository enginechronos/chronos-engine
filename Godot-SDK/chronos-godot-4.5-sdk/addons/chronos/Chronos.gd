extends Node

signal status(msg: String)
signal world_event_appended(evt: Dictionary)
signal npc_state_updated(row: Dictionary)
signal request_ok(tag: String, data: Variant)
signal request_err(tag: String, code: int, message: String, raw: Variant)

var base_url := ""
var api_key := ""
var world_id := ""
var npc_id := ""

var _rest: ChronosRESTClient
var _sse: ChronosSSEClient

const Types = preload("res://addons/chronos/ChronosTypes.gd")

func _ready() -> void:
	_rest = load("res://addons/chronos/ChronosRESTClient.gd").new()
	_sse  = load("res://addons/chronos/ChronosSSEClient.gd").new()

	add_child(_rest)
	add_child(_sse)

	_rest.request_ok.connect(_on_rest_ok)
	_rest.request_err.connect(_on_rest_err)

	_sse.stream_status.connect(_on_sse_status)
	_sse.world_event_appended.connect(_on_sse_world_event)
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

	status.emit("Chronos configured ✅")

func start() -> void:
	if base_url == "" or api_key == "" or world_id == "":
		status.emit("Chronos missing config (base_url/api_key/world_id)")
		return
	_sse.start()
	status.emit("Chronos SSE started ✅")

func stop() -> void:
	if _sse:
		_sse.stop()

func append_event(entity_id: String, event_type: String, payload: Dictionary, significant: bool = true) -> void:
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
		"max_events": max_events
	})

func get_npc_state(which_npc_id: String = "") -> void:
	var id := which_npc_id if which_npc_id != "" else npc_id
	var path := "/api/npc/state?world_id=" + Types.url_encode(world_id) + "&npc_id=" + Types.url_encode(id)
	_rest.get_json("npc.state", path)

func set_rules(rules_text: String) -> void:
	_rest.post_json("rules.set", "/api/rules/set", {
		"world_id": world_id,
		"rules_text": rules_text
	})

func get_rules() -> void:
	var path := "/api/rules/get?world_id=" + Types.url_encode(world_id)
	_rest.get_json("rules.get", path)

func _on_rest_ok(tag: String, data: Variant) -> void:
	request_ok.emit(tag, data)

func _on_rest_err(tag: String, code: int, message: String, raw: Variant) -> void:
	request_err.emit(tag, code, message, raw)

func _on_sse_status(msg: String) -> void:
	status.emit(msg)

func _on_sse_world_event(evt: Dictionary) -> void:
	world_event_appended.emit(evt)

func _on_sse_npc_state(row: Dictionary) -> void:
	npc_state_updated.emit(row)
