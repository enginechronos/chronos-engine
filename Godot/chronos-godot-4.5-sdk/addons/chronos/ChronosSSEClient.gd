extends Node
class_name ChronosSSEClient

signal stream_status(msg: String)
signal world_event_appended(evt_dict: Dictionary)
signal npc_state_updated(row_dict: Dictionary)

var base_url := ""
var api_key := ""
var world_id := ""

var reconnect_seconds := 2.0

var _client := HTTPClient.new()
var _running := false
var _requested := false
var _buf := ""
var _reconnect_timer: Timer

func _ready() -> void:
	_reconnect_timer = Timer.new()
	_reconnect_timer.one_shot = true
	add_child(_reconnect_timer)
	_reconnect_timer.timeout.connect(_force_reconnect)
	set_process(true)

func start() -> void:
	_running = true
	_requested = false
	_buf = ""
	_connect()

func stop() -> void:
	_running = false
	_requested = false
	_buf = ""
	if _client:
		_client.close()
	stream_status.emit("SSE stopped")

func _force_reconnect() -> void:
	if not _running:
		return
	_requested = false
	_buf = ""
	if _client:
		_client.close()
	_connect()

func _schedule_reconnect() -> void:
	if not _running:
		return
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

	var use_ssl := base_url.begins_with("https://")
	var host := base_url.replace("https://", "").replace("http://", "")
	var slash := host.find("/")
	if slash != -1:
		host = host.substr(0, slash)

	var port := 443 if use_ssl else 80

	# ✅ Godot 4: third arg is TLSOptions (or null), not bool
	var tls: TLSOptions = TLSOptions.client() if use_ssl else null

	var err := _client.connect_to_host(host, port, tls)
	if err != OK:
		stream_status.emit("SSE connect_to_host failed: " + str(err))
		_schedule_reconnect()
		return

	stream_status.emit("SSE connecting...")

func _process(_delta: float) -> void:
	if not _running:
		return

	_client.poll()
	var st := _client.get_status()

	if st == HTTPClient.STATUS_CONNECTED and not _requested:
		var path := "/api/stream/world?world_id=" + ChronosTypes.url_encode(world_id)

		var headers := PackedStringArray()
		headers.append("Accept: text/event-stream")
		headers.append("Cache-Control: no-cache")
		headers.append("Authorization: Bearer " + api_key.strip_edges())

		# Godot 4: request(method, url, headers, body)
		var req_err := _client.request(HTTPClient.METHOD_GET, path, headers, "")
		if req_err != OK:
			stream_status.emit("SSE request failed: " + str(req_err))
			_schedule_reconnect()
			return

		_requested = true
		stream_status.emit("SSE connected ✅")

	if st == HTTPClient.STATUS_BODY:
		var chunk: PackedByteArray = _client.read_response_body_chunk()
		if chunk.size() > 0:
			_buf += chunk.get_string_from_utf8()
			_consume_sse_buffer()

	if st == HTTPClient.STATUS_DISCONNECTED or st == HTTPClient.STATUS_CANT_CONNECT or st == HTTPClient.STATUS_CONNECTION_ERROR:
		if _running:
			stream_status.emit("SSE disconnected, reconnecting...")
			_schedule_reconnect()

func _consume_sse_buffer() -> void:
	while true:
		var idx := _buf.find("\n\n")
		if idx == -1:
			break

		var raw := _buf.substr(0, idx)
		_buf = _buf.substr(idx + 2, _buf.length())

		if raw.begins_with(":"):
			continue

		var evt := _parse_sse_event(raw)
		if evt.is_empty():
			continue

		if evt.has("event") and evt.has("data") and typeof(evt["data"]) == TYPE_DICTIONARY:
			var name := String(evt["event"])
			if name == "world_event_appended":
				world_event_appended.emit(evt["data"])
			elif name == "npc_state_updated":
				npc_state_updated.emit(evt["data"])

func _parse_sse_event(raw: String) -> Dictionary:
	var out := {}
	var event_name := ""
	var data_lines: Array[String] = []

	for line in raw.split("\n"):
		if line.begins_with("event:"):
			event_name = line.replace("event:", "").strip_edges()
		elif line.begins_with("data:"):
			data_lines.append(line.replace("data:", "").strip_edges())

	if event_name != "":
		out["event"] = event_name

	if not data_lines.is_empty():
		var data_text := "\n".join(data_lines)
		out["data"] = ChronosTypes.safe_json_parse(data_text)

	return out
