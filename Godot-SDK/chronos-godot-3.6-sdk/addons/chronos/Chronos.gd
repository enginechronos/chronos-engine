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

# --------------------------------------------------
# Phase 3 Plug-and-Play runtime settings
# --------------------------------------------------
var auto_brain_enabled := true
var auto_brain_min_interval_sec := 2
var auto_brain_max_events := 50

var _append_meta_q := []
var _last_brain_unix := 0

var _started := false
var _configured := false


func _ready():
	if _rest == null:
		_rest = load("res://addons/chronos/ChronosRESTClient.gd").new()
		add_child(_rest)

	if _sse == null:
		_sse = load("res://addons/chronos/ChronosSSEClient.gd").new()
		add_child(_sse)

	if not _rest.is_connected("request_ok", self, "_on_rest_ok"):
		_rest.connect("request_ok", self, "_on_rest_ok")
	if not _rest.is_connected("request_err", self, "_on_rest_err"):
		_rest.connect("request_err", self, "_on_rest_err")

	if not _sse.is_connected("stream_status", self, "_on_sse_status"):
		_sse.connect("stream_status", self, "_on_sse_status")
	if not _sse.is_connected("world_event_appended", self, "_on_sse_world_event"):
		_sse.connect("world_event_appended", self, "_on_sse_world_event")
	if not _sse.is_connected("npc_state_updated", self, "_on_sse_npc_state"):
		_sse.connect("npc_state_updated", self, "_on_sse_npc_state")


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
	emit_signal("status", "Chronos configured ✅")


func configure_runtime(_auto_brain_enabled: bool = true, _auto_brain_min_interval_sec: int = 2, _auto_brain_max_events: int = 50) -> void:
	auto_brain_enabled = _auto_brain_enabled
	auto_brain_min_interval_sec = max(0, _auto_brain_min_interval_sec)
	auto_brain_max_events = clamp(_auto_brain_max_events, 5, 200)

	emit_signal("status", "Chronos runtime configured ✅ auto_brain=" + str(auto_brain_enabled))


func start() -> void:
	if not _configured:
		emit_signal("status", "Chronos missing config. Call Chronos.configure() first.")
		return

	if _started:
		emit_signal("status", "Chronos SSE already running")
		return

	if base_url == "" or api_key == "" or world_id == "":
		emit_signal("status", "Chronos missing config (base_url/api_key/world_id)")
		return

	_started = true
	_sse.start()
	emit_signal("status", "Chronos SSE started ✅")


func stop() -> void:
	if not _started:
		return

	_started = false
	if _sse:
		_sse.stop()


func restart() -> void:
	stop()
	start()


# --------------------------------------------------
# Public SDK API
# --------------------------------------------------
func append_event(entity_id: String, event_type: String, payload: Dictionary, significant: bool = true, auto_brain_override: int = -1) -> void:
	var should_auto := auto_brain_enabled
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
		"max_events": clamp(max_events, 5, 200)
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


# --------------------------------------------------
# Internal helpers
# --------------------------------------------------
func _try_auto_brain_from_append(meta: Dictionary) -> void:
	if not meta.has("auto_brain") or not bool(meta["auto_brain"]):
		return

	if not meta.has("significant") or not bool(meta["significant"]):
		return

	var now = OS.get_unix_time()

	if now < _last_brain_unix + auto_brain_min_interval_sec:
		emit_signal("status", "Chronos auto brain skipped (debounced) for event: " + str(meta.get("event_type", "")))
		return

	_last_brain_unix = now
	emit_signal("status", "Chronos auto brain triggered ✅")
	brain_think(auto_brain_max_events)


# --------------------------------------------------
# Internal handlers
# --------------------------------------------------
func _on_rest_ok(tag, data):
	emit_signal("request_ok", tag, data)

	# successful append_event can automatically trigger brain_think()
	if tag == "events.append":
		if _append_meta_q.size() > 0:
			var meta = _append_meta_q.pop_front()
			_try_auto_brain_from_append(meta)
		return

	# If game asks for npc.state directly, also emit npc_state_updated
	if tag == "npc.state" and typeof(data) == TYPE_DICTIONARY and data.has("npc_id") and data.has("state"):
		emit_signal("npc_state_updated", {
			"world_id": data.get("world_id", world_id),
			"npc_id": data["npc_id"],
			"state": data["state"],
			"updated_at": data.get("updated_at", Types.iso_now())
		})
		return

	# Emit immediate update for local brain path
	if tag == "brain.think" and typeof(data) == TYPE_DICTIONARY and data.has("npc_state"):
		emit_signal("npc_state_updated", {
			"world_id": world_id,
			"npc_id": npc_id,
			"state": data["npc_state"],
			"updated_at": Types.iso_now()
		})
		return


func _on_rest_err(tag, code, message, raw):
	if tag == "events.append" and _append_meta_q.size() > 0:
		_append_meta_q.pop_front()

	emit_signal("request_err", tag, code, message, raw)


func _on_sse_status(msg):
	emit_signal("status", msg)


func _on_sse_world_event(evt):
	emit_signal("world_event_appended", evt)


func _on_sse_npc_state(row):
	emit_signal("npc_state_updated", row)
