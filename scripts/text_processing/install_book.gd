extends Node

class_name InstallBook

var translation = ""
var source_reference:SourceReference = null
var book = ""

## The total number of iterations that will be required to complete operation.
var total_iterations:int = 0
## The number of iterations that have been completed.
var completed_iterations:int = 0

signal book_install_completed
signal book_install_progress_updated(completed_iterations:int, total_iterations:int)


func _init(book:String) -> void:
	self.book = book.strip_edges()
	var source_reference_list:SourceReferenceList = SourceReferenceList.new()
	source_reference = source_reference_list.get_book(book)
	
	if not source_reference:
		print("Book is null. It is possible the book does not exist in scrollmapper.")
		return
	
	if source_reference.content_type == "extrabiblical":
		self.translation = "scrollmapper"
	else:
		self.translation = source_reference.book

func check_and_delete_existing_book():
	var book_model = BookModel.new(translation)
	book_model.find_book_by_name(book)
	if book_model.id != 0:
		var verse_model = VerseModel.new(translation)
		var verses = verse_model.get_verses(book)
		for verse in verses:
			verse_model.id = verse["verse_id"]
			verse_model.delete()
		book_model.delete()

func is_book_file_available() -> bool:
	var data_manager:DataManager = DataManager.new()
	var book_path = data_manager.get_book_path(book)
	var book_file = FileAccess.open(book_path, FileAccess.READ)
	if book_file == null:
		return false
	return true

func install() -> bool:
	if source_reference == null:
		return false
	var data_manager:DataManager = DataManager.new()
	var book_path = data_manager.get_book_path(book)
	var book_file = FileAccess.open(book_path, FileAccess.READ)
	if book_file == null:
		Command.print_to_console("Book file is unavailable: %s" % book)
		return false
	var book_text_file = book_file.get_as_text()
	var json = JSON.new()
	var error = json.parse(book_text_file)
	if error != OK:
		var error_message = "Error parsing book JSON."
		Command.print_to_console(error_message)
		push_error(error_message)
		return false
	var data = json.data
	if not is_valid_book_data(data):
		Command.print_to_console("Invalid book data: %s" % book)
		return false
	DialogueManager.show_progress_dialog()
	await GameManager.main.get_tree().process_frame
	total_iterations = 0
	completed_iterations = 0
	check_and_delete_existing_book()

	var translation_model = BibleTranslationModel.new()
	translation_model.translation_abbr = translation
	translation_model.title = translation.capitalize()
	translation_model.license = "Public Domain"
	translation_model.save()
	set_total_iterations(data)
	for book_data in data["books"]:
		DialogueManager.set_progress_dialogue_text("Installing %s"%book_data["name"])
		var book_model = BookModel.new(translation)
		book_model.book_name = book_data["name"]
		book_model.translation_id = translation_model.id
		book_model.save()
		for chapter_data in book_data["chapters"]:
			var verses:Array[VerseModel] = []
			for verse_data in chapter_data["verses"]:
				var verse_model = VerseModel.new(translation)
				verse_model.book_id = book_model.id
				verse_model.chapter = verse_data["chapter"]
				verse_model.verse = verse_data["verse"]
				verse_model.text = verse_data["text"]
				verses.append(verse_model)
				# Increment the number of completed iterations.
				completed_iterations += 1
				if completed_iterations % 100 == 0:
					var bulk_save:VerseModel = VerseModel.new(translation)
					bulk_save.bulk_save(verses)
					verses = []
					DialogueManager.set_progress_dialogue_values(completed_iterations, total_iterations)
					await GameManager.main.get_tree().process_frame
				# Send an updated signal.
				book_install_progress_updated.emit(completed_iterations, total_iterations)
		
			if verses.size() > 0:
				var bulk_save:VerseModel = VerseModel.new(translation)
				bulk_save.bulk_save(verses)	
				DialogueManager.set_progress_dialogue_values(completed_iterations, total_iterations)
				await GameManager.main.get_tree().process_frame

	Command.instance.print_to_console("Book %s installed."%book)
	ScriptureService.emit_books_installed()
	book_install_completed.emit()
	await GameManager.main.get_tree().process_frame
	DialogueManager.hide_progress_dialog()
	return true

## The total number of iterations that will be required to complete operation.
func set_total_iterations(data:Dictionary) -> void:
	for book_data in data["books"]:
		for chapter_data in book_data["chapters"]:
			for verse_data in chapter_data["verses"]:
				total_iterations += 1


static func is_valid_book_data(data:Variant) -> bool:
	if not data is Dictionary or not data.get("books") is Array or data["books"].is_empty():
		return false
	for book_data in data["books"]:
		if not book_data is Dictionary or not book_data.get("name") is String or not book_data.get("chapters") is Array:
			return false
		for chapter_data in book_data["chapters"]:
			if not chapter_data is Dictionary or not chapter_data.get("verses") is Array:
				return false
			for verse_data in chapter_data["verses"]:
				if not verse_data is Dictionary or not verse_data.get("text") is String:
					return false
				for key in ["chapter", "verse"]:
					if not (verse_data.get(key) is int or verse_data.get(key) is float) or verse_data[key] < 1:
						return false
	return true
