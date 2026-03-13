extends Node
class_name ChronosSSEClient

signal stream_status(msg)
signal world_event_appended(evt_dict)
signal npc_state_updated(row_dict)

var base_url := ""
var api_key := ""
var world_id := ""

var reconnect_seconds := 2.0

var _client := HTTPClient.new()
var _running := false
var _requested := false
var _buf := ""

var _reconnect_timer := Timer.new()
var _reconnect_scheduled := false
var _last_status := -999
var _disconnect_logged := false


func _ready():
	_reconnect_timer.one_shot = true
	add_child(_reconnect_timer)

	if not _reconnect_timer.is_connected("timeout", self, "_force_reconnect"):
		_reconnect_timer.connect("timeout", self, "_force_reconnect")

	set_process(true)


func start():
	if _running:
		emit_signal("stream_status", "SSE already running")
		return

	_running = true
	_requested = false
	_buf = ""
	_reconnect_scheduled = false
	_disconnect_logged = false
	_last_status = -999

	if _client:
		_client.close()

	_connect()


func stop():
	_running = false
	_requested = false
	_buf = ""
	_reconnect_scheduled = false
	_disconnect_logged = false

	if _reconnect_timer:
		_reconnect_timer.stop()

	if _client:
		_client.close()

	emit_signal("stream_status", "SSE stopped")


func _force_reconnect():
	_reconnect_scheduled = false
	_disconnect_logged = false

	if not _running:
		return

	_requested = false
	_buf = ""

	if _client:
		_client.close()

	emit_signal("stream_status", "SSE reconnecting...")
	_connect()


func _schedule_reconnect():
	if not _running:
		return

	if _reconnect_scheduled:
		return

	_reconnect_scheduled = true
	_reconnect_timer.start(reconnect_seconds)


func _connect():
	if not _running:
		return

	if base_url.strip_edges() == "" or api_key.strip_edges() == "" or world_id.strip_edges() == "":
		emit_signal("stream_status", "SSE missing config (base_url/api_key/world_id)")
		_schedule_reconnect()
		return

	_client.close()
	_buf = ""
	_requested = false
	_disconnect_logged = false

	var normalized = _normalize_base_url(base_url)
	var use_ssl = normalized.begins_with("https://")

	var host = normalized.replace("https://", "").replace("http://", "")
	var slash = host.find("/")
	if slash != -1:
		host = host.substr(0, slash)

	var port = 443 if use_ssl else 80

	var err = _client.connect_to_host(host, port, use_ssl)
	if err != OK:
		emit_signal("stream_status", "SSE connect_to_host failed: " + str(err))
		_schedule_reconnect()
		return

	emit_signal("stream_status", "SSE connecting...")


func _process(_delta):
	if not _running:
		return

	_client.poll()
	var st = _client.get_status()

	if st != _last_status:
		_last_status = st

	# Connected socket → send HTTP request once
	if st == HTTPClient.STATUS_CONNECTED and not _requested:
		var path = "/api/stream/world?world_id=" + ChronosTypes.url_encode(world_id)

		var headers = PoolStringArray()
		headers.append("Accept: text/event-stream")
		headers.append("Cache-Control: no-cache")
		headers.append("Authorization: Bearer " + api_key.strip_edges())

		var req_err = _client.request(HTTPClient.METHOD_GET, path, headers)
		if req_err != OK:
			emit_signal("stream_status", "SSE request failed: " + str(req_err))
			_schedule_reconnect()
			return

		_requested = true
		_reconnect_scheduled = false
		_disconnect_logged = false
		emit_signal("stream_status", "SSE connected ✅")

	# Read SSE body
	if st == HTTPClient.STATUS_BODY:
		var chunk = _client.read_response_body_chunk()
		if chunk.size() > 0:
			_buf += chunk.get_string_from_utf8()
			_consume_sse_buffer()

	# Log disconnect only once per disconnect cycle
	if st == HTTPClient.STATUS_DISCONNECTED or st == HTTPClient.STATUS_CANT_CONNECT or st == HTTPClient.STATUS_CONNECTION_ERROR:
		if _running:
			if not _disconnect_logged:
				_disconnect_logged = true
				emit_signal("stream_status", "SSE disconnected, reconnecting...")
			_schedule_reconnect()


func _consume_sse_buffer():
	while true:
		var idx = _buf.find("\n\n")
		if idx == -1:
			break

		var raw = _buf.substr(0, idx)
		_buf = _buf.substr(idx + 2, _buf.length())

		if raw.begins_with(":"):
			continue

		var evt = _parse_sse_event(raw)
		if evt.empty():
			continue

		if evt.has("event") and evt.has("data") and typeof(evt["data"]) == TYPE_DICTIONARY:
			var name = String(evt["event"])

			if name == "world_event_appended":
				emit_signal("world_event_appended", evt["data"])
			elif name == "npc_state_updated":
				emit_signal("npc_state_updated", evt["data"])
			elif name == "stream_error":
				emit_signal("stream_status", "SSE stream error")
			elif name == "heartbeat":
				pass
			elif name == "hello":
				pass
			elif name == "replay":
				pass
			elif name == "npc_state_snapshot":
				pass


func _parse_sse_event(raw: String) -> Dictionary:
	var out := {}
	var event_name := ""
	var data_lines := []

	var lines = raw.split("\n")
	for line in lines:
		if line.begins_with("event:"):
			event_name = line.replace("event:", "").strip_edges()
		elif line.begins_with("data:"):
			data_lines.append(line.replace("data:", "").strip_edges())

	if event_name != "":
		out["event"] = event_name

	if data_lines.size() > 0:
		var data_text = PoolStringArray(data_lines).join("\n")
		out["data"] = ChronosTypes.safe_json_parse(data_text)

	return out


func _normalize_base_url(u: String) -> String:
	var s = u.strip_edges()
	if s == "":
		return ""
	if not (s.begins_with("http://") or s.begins_with("https://")):
		s = "https://" + s
	while s.ends_with("/"):
		s = s.substr(0, s.length() - 1)
	return s
