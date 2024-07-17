@tool
class_name PocketBase


var auth_store := AuthStore.new()


var _host:String
var _port:int
var _collection:PocketBaseCollection


func _init(host:String, port:int) -> void:
	_host = host
	_port = port


func collection(collection:String) -> PocketBaseCollection:
	if _collection:
		_collection._collection = collection
	else:
		_collection = PocketBaseCollection.new(self, _host, _port, collection)
	return _collection


