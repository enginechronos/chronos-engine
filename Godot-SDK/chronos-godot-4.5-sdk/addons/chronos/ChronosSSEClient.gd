extends Node
class_name ChronosSSEClient

signal stream_status(msg: String)
signal world_event_appended(evt_dict: Dictionary)
signal npc_state_updated(row_dict: Dictionary)

const Types = preload("res://addons/chronos/ChronosTypes.gd")

var base_url: String = ""
var api_key: String = ""
var world_id: String = ""

var reconnect_seconds: float = 2.0

var _client: HTTPClient = HTTPClient.new()
var _running: bool = false
var _requested: bool = false
var _buf: String = ""

var _reconnect_timer: Timer
var _reconnect_scheduled: bool = false
var _last_status: int = -999
var _disconnect_logged: bool = false


func _ready() -> void:
	_reconnect_timer = Timer.new()
	_reconnect_timer.one_shot = true
	add_child(_reconnect_timer)
	_reconnect_timer.timeout.connect(_force_reconnect)
	set_process(true)


func start() -> void:
	if _running:
		stream_status.emit("SSE already running")
		return

	_running = true
	_requested = false
	_buf = ""
	_reconnect_scheduled = false
	_disconnect_logged = false
	_last_status = -999
	_client.close()
	_connect()


func stop() -> void:
	_running = false
	_requested = false
	_buf = ""
	_reconnect_scheduled = false
	_disconnect_logged = false

	if _reconnect_timer:
		_reconnect_timer.stop()

	_client.close()
	stream_status.emit("SSE stopped")


func _force_reconnect() -> void:
	_reconnect_scheduled = false
	_disconnect_logged = false

	if not _running:
		return

	_requested = false
	_buf = ""
	_client.close()
	stream_status.emit("SSE reconnecting...")
	_connect()


func _schedule_reconnect() -> void:
	if not _running:
		return
	if _reconnect_scheduled:
		return

	_reconnect_scheduled = true
	_reconnect_timer.start(reconnect_seconds)


func _connect() -> void:
	if not _running:
		return

	if base_url.strip_edges() == "" or api_key.strip_edges() == "" or world_id.strip_edges() == "":
		stream_status.emit("SSE missing config (base_url/api_key/world_id)")
		_schedule_reconnect()
		return

	_client.close()
	_buf = ""
	_requested = false
	_disconnect_logged = false

	var normalized: String = _normalize_base_url(base_url)
	var use_ssl: bool = normalized.begins_with("https://")

	var host: String = normalized.replace("https://", "").replace("http://", "")
	var slash: int = host.find("/")
	if slash != -1:
		host = host.substr(0, slash)

	var port: int = 443 if use_ssl else 80
	var err: int = _client.connect_to_host(host, port, TLSOptions.client() if use_ssl else null)
	if err != OK:
		stream_status.emit("SSE connect_to_host failed: " + str(err))
		_schedule_reconnect()
		return

	stream_status.emit("SSE connecting...")


func _process(_delta: float) -> void:
	if not _running:
		return

	_client.poll()
	var st: int = _client.get_status()

	if st != _last_status:
		_last_status = st

	if st == HTTPClient.STATUS_CONNECTED and not _requested:
		var path: String = "/api/stream/world?world_id=" + Types.url_encode(world_id)

		var headers: PackedStringArray = PackedStringArray()
		headers.append("Accept: text/event-stream")
		headers.append("Cache-Control: no-cache")
		headers.append("Authorization: Bearer " + api_key.strip_edges())

		var req_err: int = _client.request(HTTPClient.METHOD_GET, path, headers)
		if req_err != OK:
			stream_status.emit("SSE request failed: " + str(req_err))
			_schedule_reconnect()
			return

		_requested = true
		_reconnect_scheduled = false
		_disconnect_logged = false
		stream_status.emit("SSE connected ✅")

	if st == HTTPClient.STATUS_BODY:
		var chunk: PackedByteArray = _client.read_response_body_chunk()
		if not chunk.is_empty():
			_buf += chunk.get_string_from_utf8()
			_consume_sse_buffer()

	if st == HTTPClient.STATUS_DISCONNECTED or st == HTTPClient.STATUS_CANT_CONNECT or st == HTTPClient.STATUS_CONNECTION_ERROR:
		if _running:
			if not _disconnect_logged:
				_disconnect_logged = true
				stream_status.emit("SSE disconnected, reconnecting...")
			_schedule_reconnect()


func _consume_sse_buffer() -> void:
	while true:
		var idx: int = _buf.find("\n\n")
		if idx == -1:
			break

		var raw: String = _buf.substr(0, idx)
		_buf = _buf.substr(idx + 2)

		if raw.begins_with(":"):
			continue

		var evt: Dictionary = _parse_sse_event(raw)
		if evt.is_empty():
			continue

		if evt.has("event") and evt.has("data") and evt["data"] is Dictionary:
			var name: String = str(evt["event"])

			if name == "world_event_appended":
				world_event_appended.emit(evt["data"])
			elif name == "npc_state_updated":
				npc_state_updated.emit(evt["data"])


func _parse_sse_event(raw: String) -> Dictionary:
	var out: Dictionary = {}
	var event_name: String = ""
	var data_lines: Array[String] = []

	for line in raw.split("\n"):
		if line.begins_with("event:"):
			event_name = line.replace("event:", "").strip_edges()
		elif line.begins_with("data:"):
			data_lines.append(line.replace("data:", "").strip_edges())

	if event_name != "":
		out["event"] = event_name

	if not data_lines.is_empty():
		var data_text: String = "\n".join(data_lines)
		out["data"] = Types.safe_json_parse(data_text)

	return out


func _normalize_base_url(u: String) -> String:
	var s: String = u.strip_edges()
	if s == "":
		return ""
	if not (s.begins_with("http://") or s.begins_with("https://")):
		s = "https://" + s
	while s.ends_with("/"):
		s = s.substr(0, s.length() - 1)
	return s
