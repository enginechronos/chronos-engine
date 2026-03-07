extends Node
class_name ChronosTypes

static func safe_json_parse(text: String) -> Variant:
	if text == null:
		return {}
	var t := String(text).strip_edges()
	if t == "":
		return {}
	var parsed = JSON.parse_string(t) # Godot 4
	if parsed == null:
		return {"raw": t}
	return parsed

static func json_print(obj: Variant) -> String:
	return JSON.stringify(obj)

static func url_encode(s: String) -> String:
	# Simple safe encoder (good enough for ids)
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
	var d: Dictionary = Time.get_datetime_dict_from_system(true) # UTC
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [d.year, d.month, d.day, d.hour, d.minute, d.second]
