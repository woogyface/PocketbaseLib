class_name PocketBaseRecord


var _http_result:HTTPResult
var json:
	get: return _http_result.json


var exception:Dictionary:
	get:
		return _http_result.json


func _init(http_result:HTTPResult) -> void:
	_http_result = http_result


func is_exception() -> bool:
	return "code" in _http_result.json


