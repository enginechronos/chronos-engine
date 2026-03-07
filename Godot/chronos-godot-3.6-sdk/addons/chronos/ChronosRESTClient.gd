extends Node
class_name ChronosRESTClient

signal request_ok(tag, data)
signal request_err(tag, code, message, raw)

var base_url := ""
var api_key := ""

var _http := HTTPRequest.new()
var _busy := false

# queue items: { "method": int, "tag": String, "path": String, "body": String }
var _q := []

func _ready():
	add_child(_http)
	_http.connect("request_completed", self, "_on_done")

func _headers_json() -> PoolStringArray:
	var h := PoolStringArray()
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
		emit_signal("request_err", tag, 0, "ChronosRESTClient: base_url missing. Call Chronos.configure() first.", {"base_url": base_url, "path": path})
		return

	var body = ChronosTypes.json_print(body_dict)
	_q.append({"method": HTTPClient.METHOD_POST, "tag": tag, "url": url, "body": body})
	_pump()

func get_json(tag: String, path: String) -> void:
	var url = _build_url(path)
	if url == "":
		emit_signal("request_err", tag, 0, "ChronosRESTClient: base_url missing. Call Chronos.configure() first.", {"base_url": base_url, "path": path})
		return

	_q.append({"method": HTTPClient.METHOD_GET, "tag": tag, "url": url, "body": ""})
	_pump()

func _pump():
	if _busy:
		return
	if _q.size() == 0:
		return

	_busy = true
	var item = _q.pop_front()

	# Store tag on the HTTPRequest metadata so we know which response it belongs to
	_http.set_meta("tag", item["tag"])

	var err = _http.request(item["url"], _headers_json(), true, item["method"], item["body"])
	if err != OK:
		_busy = false
		emit_signal("request_err", item["tag"], 0, "Local request error: " + str(err), {"local_err": err, "url": item["url"]})
		# continue with next
		_pump()

func _on_done(_result, response_code, _headers, body):
	var tag = ""
	if _http.has_meta("tag"):
		tag = str(_http.get_meta("tag"))

	var text := ""
	if body != null and body.size() > 0:
		text = body.get_string_from_utf8()

	var json = ChronosTypes.safe_json_parse(text)

	if response_code >= 200 and response_code < 300:
		emit_signal("request_ok", tag, json)
	else:
		var msg = ""
		if typeof(json) == TYPE_DICTIONARY and json.has("message"):
			msg = str(json["message"])
		elif typeof(json) == TYPE_DICTIONARY and json.has("error"):
			msg = str(json["error"])
		else:
			msg = text
		emit_signal("request_err", tag, response_code, msg, json)

	_busy = false
	_pump()
