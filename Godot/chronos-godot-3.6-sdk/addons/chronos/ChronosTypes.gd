extends Node
class_name ChronosTypes

static func safe_json_parse(text: String):
	if text == null:
		return {}
	var t := String(text).strip_edges()
	if t == "":
		return {}
	var parsed = parse_json(t) # returns null on error in Godot 3
	if parsed == null:
		return {"raw": t}
	return parsed

static func json_print(obj) -> String:
	# Godot 3 has global to_json()
	return to_json(obj)

static func url_encode(s: String) -> String:
	var t = String(s)
	t = t.replace("%", "%25")
	t = t.replace(" ", "%20")
	t = t.replace("#", "%23")
	t = t.replace("?", "%3F")
	t = t.replace("&", "%26")
	t = t.replace("=", "%3D")
	t = t.replace("/", "%2F")
	return t

static func iso_now() -> String:
	# Minimal ISO-like timestamp for UI/debug (client-side only)
	var d = OS.get_datetime(true)
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [d.year, d.month, d.day, d.hour, d.minute, d.second]
