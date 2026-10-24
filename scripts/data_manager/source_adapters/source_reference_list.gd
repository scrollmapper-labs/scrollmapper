extends RefCounted
class_name SourceReferenceList

var source_references:Array[SourceReference] = []

func _init():
	var data_manager:DataManager = DataManager.new()
	var source_list_path = data_manager.get_source_list_path()
	var source_list:FileAccess = FileAccess.open(source_list_path, FileAccess.READ)
	if source_list == null:
		return
	var source_list_text:String = source_list.get_as_text()
	var json:JSON = JSON.new()
	var error = json.parse(source_list_text)
	
	# Check for errors in parsing the source list JSON, create json array if well.
	if error != OK or not is_valid_source_list(json.data):
		var error_message:String = "Error parsing source list JSON."
		print(error_message)
		Command.print_to_console(error_message)
		return
	var data:Array = json.data

	# Iterate over the source list and create a SourceReference object for each item
	for source_item in data:
		var language:String = source_item["language"]
		var book:String = source_item["book"]
		var title:String = source_item["title"]
		var source:String = source_item["source"]
		var content_type:String = source_item["content_type"]
		var source_reference:SourceReference = SourceReference.new(language, book, title, source, content_type)
		source_references.append(source_reference)

func get_all_sources() -> Array:
	return source_references

func get_biblical_sources() -> Array:
	var biblical_sources:Array = []
	for source_reference in source_references:
		print(source_reference.content_type)
		if source_reference.content_type == "bible":
			biblical_sources.append(source_reference)
	return biblical_sources

func get_extrabiblical_sources() -> Array:
	var extrabiblical_sources:Array = []
	for source_reference in source_references:
		if source_reference.content_type == "extrabiblical":
			extrabiblical_sources.append(source_reference)
	return extrabiblical_sources

func get_book(book_name:String) -> SourceReference:
	for source_reference in source_references:
		if source_reference.book == book_name:
			return source_reference
	return null

func get_book_source(book_name:String) -> String:
	for source_reference in source_references:
		if source_reference.book == book_name:
			return source_reference.source
	return ""


static func is_valid_source_list(data:Variant) -> bool:
	if not data is Array or data.is_empty():
		return false
	for item in data:
		if not item is Dictionary:
			return false
		for key in ["language", "book", "title", "source", "content_type"]:
			if not item.get(key) is String:
				return false
		if item["book"].is_empty() or item["book"].get_file() != item["book"] or item["book"] in [".", ".."]:
			return false
	return true
