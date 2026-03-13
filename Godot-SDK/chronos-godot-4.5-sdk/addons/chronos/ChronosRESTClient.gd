extends Node
class_name ChronosRESTClient

signal request_ok(tag: String, data: Variant)
signal request_err(tag: String, code: int, message: String, raw: Variant)

var base_url: String = ""
var api_key: String = ""

var _http: HTTPRequest
var _busy: bool = false

# queue items:
# { "method": int, "tag": String, "url": String, "body": String }
var _q: Array = []


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_done)


func _headers_json() -> PackedStringArray:
	var h: PackedStringArray = PackedStringArray()
	h.append("Content-Type: application/json")
	if api_key.strip_edges() != "":
		h.append("Authorization: Bearer " + api_key.strip_edges())
	return h


func _normalize_base_url(u: String) -> String:
	var s: String = u.strip_edges()
	if s == "":
		return ""
	if not (s.begins_with("http://") or s.begins_with("https://")):
		s = "https://" + s
	while s.ends_with("/"):
		s = s.substr(0, s.length() - 1)
	return s


func _build_url(path: String) -> String:
	var b: String = _normalize_base_url(base_url)
	if b == "":
		return ""
	var p: String = path.strip_edges()
	if not p.begins_with("/"):
		p = "/" + p
	return b + p


func post_json(tag: String, path: String, body_dict: Dictionary) -> void:
	var url: String = _build_url(path)
	if url == "":
		request_err.emit(tag, 0, "ChronosRESTClient: base_url missing. Call Chronos.configure() first.", {
			"base_url": base_url,
			"path": path
		})
		return

	var body: String = JSON.stringify(body_dict)
	_q.append({
		"method": HTTPClient.METHOD_POST,
		"tag": tag,
		"url": url,
		"body": body
	})
	_pump()


func get_json(tag: String, path: String) -> void:
	var url: String = _build_url(path)
	if url == "":
		request_err.emit(tag, 0, "ChronosRESTClient: base_url missing. Call Chronos.configure() first.", {
			"base_url": base_url,
			"path": path
		})
		return

	_q.append({
		"method": HTTPClient.METHOD_GET,
		"tag": tag,
		"url": url,
		"body": ""
	})
	_pump()


func _pump() -> void:
	if _busy:
		return
	if _q.is_empty():
		return

	_busy = true
	var item: Dictionary = _q.pop_front()

	_http.set_meta("tag", item["tag"])

	var method: int = int(item["method"])
	var err: int = _http.request(
		item["url"],
		_headers_json(),
		method,
		item["body"]
	)

	if err != OK:
		_busy = false
		request_err.emit(item["tag"], 0, "Local request error: " + str(err), {
			"local_err": err,
			"url": item["url"]
		})
		_pump()


func _on_done(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var tag: String = ""
	if _http.has_meta("tag"):
		tag = str(_http.get_meta("tag"))

	var text: String = ""
	if not body.is_empty():
		text = body.get_string_from_utf8()

	var json: Variant = {}
	if text.strip_edges() != "":
		var parsed: Variant = JSON.parse_string(text.strip_edges())
		json = parsed if parsed != null else {"raw": text}

	if response_code >= 200 and response_code < 300:
		request_ok.emit(tag, json)
	else:
		var msg: String = ""
		if json is Dictionary and json.has("message"):
			msg = str(json["message"])
		elif json is Dictionary and json.has("error"):
			msg = str(json["error"])
		else:
			msg = text
		request_err.emit(tag, response_code, msg, json)

	# IMPORTANT:
	# Always free the queue after request completion,
	# whether success or error.
	_busy = false
	_pump()
