class_name HTTPResult extends RefCounted


var error:Error
var status:HTTPClient.Status
var headers:Dictionary
var code:int
var body_length:int
var body_raw:PackedByteArray
var body:String:
	get:
		return body_raw.get_string_from_utf8()
var json:
	get:
		if body.is_empty():
			return null
		return JSON.parse_string(body)


static func _from_error(error:Error) -> HTTPResult:
	var res := HTTPResult.new()
	res.error = error
	return res

static func _from_status(status:HTTPClient.Status) -> HTTPResult:
	var res := HTTPResult.new()
	res.status = status
	return res
