class_name HTTPSSEClient

var force_shutdown:bool

var _http:HTTPClient
var _host:String
var _port:int
var _api_url:String
var _tls_options:TLSOptions
var _listeners:Dictionary

var is_connected_to_server:bool = false
var initialized_pocketbase:bool = false
var _has_stream:bool
var _token:String
var subscribe_buffer:PackedStringArray = []

var client_id:String = ""


func _init(host:String, port:int, api_url:String, token:String, tls_options:TLSOptions = null) -> void:
	_host = host
	_port = port
	_api_url = api_url
	_tls_options = tls_options
	_http = HTTPClient.new()
	_listeners = {}
	_token = token

	_has_stream = false


func subscribe(event:String, callback:Callable) -> void:
	if event not in _listeners:
		_listeners[event] = []
	_listeners[event].append(callback)
	_update_subscribtions()


func unsubscribe(event:String) -> void:
	if event in _listeners:
		_listeners.erase(event)
	_update_subscribtions()

	if len(_listeners) == 0:
		_close()


func _close() -> void:
	_http.close()
	is_connected_to_server = false
	initialized_pocketbase = false
	_has_stream = false

	force_shutdown = true


func _update_subscribtions() -> void:
	if client_id and _token and len(subscribe_buffer) > 0:
		var http_req := HTTPRequestAsync.new()
		await http_req.request_async(
			_host, _port,
			"/api/realtime",
			["Content-Type:application/json", "Authorization:%s" % _token],
			HTTPClient.METHOD_POST,
			{},
			{"clientId":client_id, "subscriptions": _listeners.keys()})


func _dispatch_event(data:Dictionary) -> void:
	for callback:Callable in _listeners[data["event"]]:
		callback.call(data["data"]["action"], data["data"]["record"])


func _try_to_connect() -> void:
	if _http.get_status() == HTTPClient.STATUS_CONNECTED:
		return

	var error := _http.connect_to_host(_host, _port, _tls_options)
	if error == OK:
		while _http.get_status() == HTTPClient.STATUS_CONNECTING or _http.get_status() == HTTPClient.STATUS_RESOLVING:
			_http.poll()
			await Engine.get_main_loop().process_frame

		if _http.get_status() == HTTPClient.STATUS_CONNECTED:
			is_connected_to_server = true


func _init_pocketbase():
	if not is_connected_to_server:
		return

	var err = _http.request(HTTPClient.METHOD_GET, "/api/realtime", ["Content-Type: application/json"])
	if err == OK:
		while _http.get_status() == HTTPClient.STATUS_REQUESTING:
			_http.poll()
			await Engine.get_main_loop().process_frame

		var response_body:PackedByteArray = []
		while _http.get_status() == HTTPClient.STATUS_BODY:
			_http.poll()
			var chunk = _http.read_response_body_chunk()
			if chunk.size() == 0:
				break
			else:
				response_body = response_body + chunk
				print("body: " + str(response_body.get_string_from_utf8()))

		var body = response_body.get_string_from_utf8()
		var splitted := body.split("\n")
		client_id = splitted[0].right(-3)
		initialized_pocketbase = true


func _request_stream() -> void:
	while _http.get_status() == HTTPClient.STATUS_CONNECTING or _http.get_status() == HTTPClient.STATUS_RESOLVING:
		_http.poll()
		await Engine.get_main_loop().process_frame

	#print("request stream status: " + str(_http.get_status()))

	if _http.get_status() == HTTPClient.STATUS_CONNECTED:
		_http.request(HTTPClient.METHOD_POST, _api_url, ["Accept: text/event-stream"])
		while _http.get_status() == HTTPClient.STATUS_REQUESTING:
			_http.poll()
			await Engine.get_main_loop().process_frame

		if _http.get_status() == HTTPClient.STATUS_BODY:
			_has_stream = true


func start_polling_async() -> void:
	while not force_shutdown:
		if not is_connected_to_server:
			await _try_to_connect()
		if is_connected_to_server and not initialized_pocketbase:
			await _init_pocketbase()
		if is_connected_to_server and initialized_pocketbase:
			await _request_stream()

		#await _clear_subscribe_buffer()
		#print("=======================")
		#print("is_connected_to_server: " + str(is_connected_to_server))
		#print("initialized_pocketbase: " + str(initialized_pocketbase))
		#print("_has_stream: " + str(_has_stream))
		#print("_http.has_response(): " + str(_http.has_response()))
		#print("_http.get_status(): " + str(_http.get_status()))

		var body_raw := PackedByteArray()
		while _http.get_status() == HTTPClient.STATUS_BODY and not force_shutdown:
			_http.poll()
			#print("polling")
			var chunk := _http.read_response_body_chunk()
			if chunk.size() == 0:
				break
			else:
				body_raw = body_raw + chunk

		var content = body_raw.get_string_from_utf8()
		if not content.is_empty() and not force_shutdown:
			print("content: " + content)
			var data := _format_event_content(content)
			_dispatch_event(data)

		await Engine.get_main_loop().process_frame

func _format_event_content(content:String) -> Dictionary:
	var splitted := content.split("\n")
	var dict := {}
	dict["event"] = splitted[1].right(-6)
	dict["data"] = JSON.parse_string(splitted[2].right(-5)) as Dictionary
	return dict
