class_name HTTPRequestAsync


func request_async(host:String, port:int, api_url:String, custom_headers := PackedStringArray(), method := HTTPClient.Method.METHOD_GET, url_parameter := {}, request_body := {}) -> HTTPResult:
	var http := HTTPClient.new()
	var error := http.connect_to_host(host, port)

	if error != OK:
		return HTTPResult._from_error(error)

	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		#print("Connecting...")
		await Engine.get_main_loop().process_frame

	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return HTTPResult._from_status(http.get_status())

	var full_api_url = api_url
	if not url_parameter.is_empty():
		full_api_url = "%s?%s" % [api_url, http.query_string_from_dict(url_parameter)]

	if not request_body.is_empty():
		error = http.request(method, full_api_url, custom_headers, JSON.stringify(request_body))
	else:
		error = http.request(method, full_api_url, custom_headers)

	if error != OK:
		http.connection
		return HTTPResult._from_error(error)

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		#print("Requesting...")
		await Engine.get_main_loop().process_frame

	if http.get_status() != HTTPClient.STATUS_BODY and http.get_status() != HTTPClient.STATUS_CONNECTED:
		return HTTPResult._from_status(http.get_status())

	if http.has_response():
		var result := HTTPResult.new()
		result.headers = http.get_response_headers_as_dictionary()
		result.code = http.get_response_code()
		result.body_length = http.get_response_body_length()

		var body_raw := PackedByteArray()
		while http.get_status() == HTTPClient.STATUS_BODY:
			http.poll()
			var chunk := http.read_response_body_chunk()
			if chunk.size() == 0:
				await Engine.get_main_loop().process_frame
			else:
				body_raw = body_raw + chunk

		result.body_raw = body_raw
		return result

	return HTTPResult._from_error(FAILED)
