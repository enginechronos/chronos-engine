extends Node

signal status(msg)
signal world_event_appended(evt)
signal npc_state_updated(row)
signal request_ok(tag, data)
signal request_err(tag, code, message, raw)

var base_url := ""
var api_key := ""
var world_id := ""
var npc_id := ""

var _rest = null
var _sse = null

const Types = preload("res://addons/chronos/ChronosTypes.gd")

func _ready():
	_rest = load("res://addons/chronos/ChronosRESTClient.gd").new()
	_sse  = load("res://addons/chronos/ChronosSSEClient.gd").new()

	add_child(_rest)
	add_child(_sse)

	_rest.connect("request_ok", self, "_on_rest_ok")
	_rest.connect("request_err", self, "_on_rest_err")

	_sse.connect("stream_status", self, "_on_sse_status")
	_sse.connect("world_event_appended", self, "_on_sse_world_event")
	_sse.connect("npc_state_updated", self, "_on_sse_npc_state")

func configure(_base_url: String, _api_key: String, _world_id: String, _npc_id: String = "guard_1") -> void:
	# ✅ FIX 2 applied: Auto-adds https:// protocol if missing
	base_url = _base_url.strip_edges()
	if base_url != "" and not (base_url.begins_with("http://") or base_url.begins_with("https://")):
		base_url = "https://" + base_url

	api_key = _api_key.strip_edges()
	world_id = _world_id.strip_edges()
	npc_id = _npc_id.strip_edges()

	# Apply the sanitized URL to child clients
	_rest.base_url = base_url
	_rest.api_key = api_key

	_sse.base_url = base_url
	_sse.api_key = api_key
	_sse.world_id = world_id

	emit_signal("status", "Chronos configured ✅")

func start() -> void:
	if base_url == "" or api_key == "" or world_id == "":
		emit_signal("status", "Chronos missing config (base_url/api_key/world_id)")
		return
	_sse.start()
	emit_signal("status", "Chronos SSE started ✅")

func stop() -> void:
	if _sse:
		_sse.stop()

# -----------------------------
# Public SDK API
# -----------------------------
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
	var id = which_npc_id if which_npc_id != "" else npc_id
	var path = "/api/npc/state?world_id=" + Types.url_encode(world_id) + "&npc_id=" + Types.url_encode(id)
	_rest.get_json("npc.state", path)

func set_rules(rules_text: String) -> void:
	_rest.post_json("rules.set", "/api/rules/set", {
		"world_id": world_id,
		"rules_text": rules_text
	})

func get_rules() -> void:
	var path = "/api/rules/get?world_id=" + Types.url_encode(world_id)
	_rest.get_json("rules.get", path)

# -----------------------------
# Internal handlers
# -----------------------------
func _on_rest_ok(tag, data):
	emit_signal("request_ok", tag, data)

	if tag == "brain.think" and typeof(data) == TYPE_DICTIONARY and data.has("npc_state"):
		emit_signal("npc_state_updated", {
			"npc_id": npc_id,
			"state": data["npc_state"],
			"updated_at": Types.iso_now()
		})

func _on_rest_err(tag, code, message, raw):
	emit_signal("request_err", tag, code, message, raw)

func _on_sse_status(msg):
	emit_signal("status", msg)

func _on_sse_world_event(evt):
	emit_signal("world_event_appended", evt)

func _on_sse_npc_state(row):
	emit_signal("npc_state_updated", row)
