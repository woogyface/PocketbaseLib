class_name PocketBaseCollection


var _client:PocketBase
var _sse_client:HTTPSSEClient
var _host:String
var _port:int
var _collection:String


func _init(client: PocketBase, host:String, port:int, collection:String) -> void:
	_client = client
	_host = host
	_port = port
	_collection = collection


func _format_header(header:Array[String]) -> Array[String]:
	if _client.auth_store.token != "":
		header.append("Authorization:%s" % _client.auth_store.token)

	return header


func get_list(page:int, per_page:int, data:Dictionary={}) -> Variant:
	data["page"] = page
	data["perPage"] = per_page

	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_GET,
		data)
	return respond.json


func get_full_list(data:Dictionary={}) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_GET,
		data)
	return respond.json


func get_first_list_item(filter:String, data:Dictionary={}) -> Variant:
	data["filter"] = filter

	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_GET,
		data)
	if "items" in respond.json and len(respond.json["items"]) > 0:
		return respond.json["items"][0]
	return {}


func get_one(id:String, data:Dictionary={}) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records/%s" % [_collection, id],
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_GET,
		data)
	return respond.json


func create(data:Dictionary={}) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		data)
	return respond.json


func update(id:String, data:Dictionary={}) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records/%s" % [_collection, id],
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_PATCH,
		{},
		data)
	return respond.json


func delete(id:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records/%s" % [_collection, id],
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_DELETE)
	return respond.json


################################################
# TODO: ADD SUBSCRIBE/UNSUBSCRIBE VIA SSE
# https://github.com/WolfgangSenff/HTTPSSEClient
################################################
func subscribe(topic:String, callback:Callable, options:Dictionary = {}) -> Variant:
	if not _sse_client:
		_sse_client = HTTPSSEClient.new(_host, _port, "/api/realtime", _client.auth_store.token)
		_sse_client.start_polling_async()
	if topic.is_empty():
		push_error("Topic must be set.")
		return null
	_sse_client.subscribe("%s/%s" % [_collection, topic], callback)

	return null


func unsubscribe(topic:String) -> Variant:
	if _sse_client:
		_sse_client.ubsubscribe("%s/%s" % [_collection, topic])
	return null


func auth_with_password(username_or_email:String, password:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/auth-with-password" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		{"identity": username_or_email, "password": password})
	if "token" in respond.json and "record" in respond.json:
		_client.auth_store.save(respond.json["token"], respond.json["record"])
	return respond.json


func auth_refresh() -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/auth-refresh" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST)
	if "token" in respond.json and "record" in respond.json:
		_client.auth_store.save(respond.json["token"], respond.json["record"])
	return respond.json

func request_verification(email:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/request-verification" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		{"email": email})
	return respond.json


func confirm_verification(token:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/confirm-verification" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		{"token": token})
	return respond.json


func request_password_reset(email:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/request-password-reset" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		{"email": email})
	return respond.json


func confirm_password_reset(token:String, new_password:String, new_password_confirm:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/confirm-password-reset" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		{"token": token, "password": new_password, "passwordConfirm": new_password_confirm})
	return respond.json


func request_email_change(email:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/request-email-change" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		{"email": email})
	return respond.json


func confirm_email_change(token:String, password:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/confirm-email-change" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		{},
		{"token": token, "password": password})
	return respond.json


func list_auth_methods() -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/auth-methods" % _collection,
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_GET)
	return respond.json


func list_external_auths(id:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records/%s/external-auths" % [_collection, id],
		_format_header(["Content-Type: application/json"]),
		HTTPClient.METHOD_GET)
	return respond.json


func unlink_external_auths(id:String, provider:String) -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/collections/%s/records/%s/external-auths/%s" % [_collection, id, provider],
		["Content-Type: application/json"],
		HTTPClient.METHOD_DELETE)
	return respond.json


func test() -> Variant:
	var respond:HTTPResult = await _make_request(
		"/api/realtime",
		["Accept: text/event-stream"],
		HTTPClient.METHOD_POST)
	return respond.json


func _make_request(api_url:String, header:Array[String] = ["Content-Type: application/json"], method := HTTPClient.Method.METHOD_GET, url_parameter := {}, request_body := {}) -> Variant:
	var http_req := HTTPRequestAsync.new()
	return await http_req.request_async(_host, _port, api_url, _format_header(header), method, url_parameter, request_body)
