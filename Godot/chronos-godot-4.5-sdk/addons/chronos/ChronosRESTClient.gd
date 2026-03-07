extends Node
class_name ChronosRESTClient

signal request_ok(tag: String, data: Variant)
signal request_err(tag: String, code: int, message: String, raw: Variant)

var base_url := ""
var api_key := ""

var _http: HTTPRequest
var _busy := false
var _q: Array = [] # items: {method:int, tag:String, url:String, body:String}

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_done)

func _headers_json() -> PackedStringArray:
	var h := PackedStringArray()
	h.append("Content-Type: application/json")
	if api_key.strip_edges() != "":
		h.append("Authorization: Bearer " + api_key.strip_edges())
	return h

func _normalize_base_url(u: String) -> String:
	var s = u.strip_edges()
	if s == "":
		return ""
	if not (s.begins_with("http://") or s.begins_with("https://")):
		s = "https://" + s
	while s.ends_with("/"):
		s = s.substr(0, s.length() - 1)
	return s

func _build_url(path: String) -> String:
	var b = _normalize_base_url(base_url)
	if b == "":
		return ""
	var p = path.strip_edges()
	if not p.begins_with("/"):
		p = "/" + p
	return b + p

func post_json(tag: String, path: String, body_dict: Dictionary) -> void:
	var url = _build_url(path)
	if url == "":
		request_err.emit(tag, 0, "ChronosRESTClient: base_url missing. Call Chronos.configure() first.", {"base_url": base_url, "path": path})
		return

	var body = ChronosTypes.json_print(body_dict)
	_q.append({"method": HTTPClient.METHOD_POST, "tag": tag, "url": url, "body": body})
	_pump()

func get_json(tag: String, path: String) -> void:
	var url = _build_url(path)
	if url == "":
		request_err.emit(tag, 0, "ChronosRESTClient: base_url missing. Call Chronos.configure() first.", {"base_url": base_url, "path": path})
		return

	_q.append({"method": HTTPClient.METHOD_GET, "tag": tag, "url": url, "body": ""})
	_pump()

func _pump() -> void:
	if _busy:
		return
	if _q.is_empty():
		return

	_busy = true
	var item: Dictionary = _q.pop_front()

	_http.set_meta("tag", item["tag"])

	# Godot 4 signature: request(url, headers, method, request_data)
	var err: int = _http.request(item["url"], _headers_json(), item["method"], item["body"])
	if err != OK:
		_busy = false
		request_err.emit(String(item["tag"]), 0, "Local request error: " + str(err), {"local_err": err, "url": item["url"]})
		_pump()

func _on_done(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var tag := ""
	if _http.has_meta("tag"):
		tag = String(_http.get_meta("tag"))

	var text := ""
	if body != null and body.size() > 0:
		text = body.get_string_from_utf8()

	var json: Variant = ChronosTypes.safe_json_parse(text)

	if response_code >= 200 and response_code < 300:
		request_ok.emit(tag, json)
	else:
		var msg := ""
		if typeof(json) == TYPE_DICTIONARY and (json as Dictionary).has("message"):
			msg = String((json as Dictionary)["message"])
		elif typeof(json) == TYPE_DICTIONARY and (json as Dictionary).has("error"):
			msg = String((json as Dictionary)["error"])
		else:
			msg = text
		request_err.emit(tag, response_code, msg, json)

	_busy = false
	_pump()
