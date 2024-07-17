class_name AuthStore


signal on_change(token:String, model:Variant)


var token:String = ""
var model:Variant = null
var is_valid:bool:
	get: return not JWT.is_token_expired(token)
var is_admin:bool:
	get: return JWT.get_token_payload(token)["type"] == "admin"
var is_auth_record:bool:
	get: return JWT.get_token_payload(token)["type"] == "authRecord"


func save(token_:String, model_:Variant) -> void:
	token = token_
	model = model_

	# trigger change
	on_change.emit(token, model)


func clear() -> void:
	token = ""
	model = null

	on_change.emit(token, model)
