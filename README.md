# PocketbaseLib

A PocketBase lib written in GDScript 4.x. Far from feature complete but the basics are covered 🤞

quick usage summary:
```GDScript
class_name PocketBaseExamples extends Control


var pb := PocketBase.new("http://127.0.0.1", 8081)


func _ready() -> void:
	realtime_example()


func login_example() -> void:
	var username := "woogy"
	var password := "12345678"
	var result := await pb.collection("users").auth_with_password(username, password)
	_print("login", result)


func list_search() -> void:
	# fetch a paginated records list
	var result_list := await pb.collection("temp").get_list(1, 50, {
		"filter" : "created >= '2024-07-16 00:00:00'"
	})
	_print("get_list", result_list)

	# you can also fetch all records at once via getFullList
	var records := await pb.collection("temp").get_full_list({
		"sort" : "-created"
	})
	_print("get_full_list", records)

	# or fetch only the first record that matches the specified filter
	var result := await pb.collection("temp").get_first_list_item("data='3748291'")
	_print("get_first_list_item", result)


func view_example() -> void:
	var result := await pb.collection("temp").get_one("hmgeq2zj2pgqn1i")
	_print("get_one", result)


func create_example() -> void:
	# example create data
	var data := {
		"data": Time.get_ticks_msec()
	}

	var record := await pb.collection("temp").create(data)
	_print("create", record)


func update_example() -> void:
	# example create data
	var data := {
		"data": "That will be changed"
	}

	var record := await pb.collection("temp").create(data)
	_print("create", record)

	#example update data
	var updated_data := {
		"data": "This is the new value"
	}
	var updated_record := await pb.collection("temp").update(record["id"], updated_data)
	_print("update", updated_record)


func delete_example() -> void:
	# example create data
	var data := {
		"data": "i will be deleted"
	}

	var record := await pb.collection("temp").create(data)
	_print("create", record)

	# deleted is null when successful else it is a dictionary
	var deleted := await pb.collection("temp").delete(record["id"])
	_print("delete", deleted)


func realtime_example() -> void:
	# login if needed
	var username := "woogy"
	var password := "12345678"
	await pb.collection("users").auth_with_password(username, password)

	# subscribe to every event
	pb.collection("temp").subscribe("*", temp_callback)

	# create data to test the subscription
	var data := {
		"data": Time.get_ticks_msec()
	}
	await pb.collection("temp").create(data)

	# unsubscribe if needed
	pb.collection("temp").unsubscribe("*")


func temp_callback(action:String, record:Variant) -> void:
	_print("temp_callback", {"action": action, "record": record})


func _print(title:String, data:Variant) -> void:
	print("\n========== %s ==========" % title)
	var pretty = JSON.stringify(data, "\t")
	print(pretty)
```
