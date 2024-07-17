class_name JWT


static func get_token_payload(token:String) -> Variant:
	if token.is_empty():
		return {}

	var payload := token.split(".")[1]
	# for godot base64 strings HAVE TO end with == to be decoded correctly
	# see https://github.com/godotengine/godot/issues/94028
	if not payload.ends_with("=="):
		payload += "=="
	var decoded_payload := Marshalls.base64_to_utf8(payload)

	return JSON.parse_string(decoded_payload)


static func is_token_expired(token:String, expiration_threashold:int = 0) -> bool:
	var payload := get_token_payload(token)
	if not payload.is_empty():
		if not "exp" in payload or payload["exp"] - expiration_threashold > int(Time.get_unix_time_from_system()):
			return false

	return true
