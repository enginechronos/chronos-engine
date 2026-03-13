extends Node
class_name ChronosTypes

static func safe_json_parse(text: String) -> Variant:
	if text.strip_edges() == "":
		return {}

	var parsed: Variant = JSON.parse_string(text.strip_edges())
	if parsed == null:
		return {"raw": text}
	return parsed


static func json_print(obj: Variant) -> String:
	return JSON.stringify(obj)


static func url_encode(s: String) -> String:
	return s.uri_encode()


static func iso_now() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		dt.year, dt.month, dt.day,
		dt.hour, dt.minute, dt.second
	]
