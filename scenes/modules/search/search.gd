extends MarginContainer

class_name Search

#region search / range
@export_group("Search Type")
@export var check_button_search_type: CheckButton 
#endregion

#region togglable search mode containers
@export_group("Toggleable Search Mode Containers")
@export var margin_container_search: MarginContainer 
@export var h_box_container_range: HBoxContainer 
#endregion

#region main search
@export_group("Main Search")
@export var option_scope: OptionButton 
@export var option_translation: OptionButton 
@export var option_books: OptionButton 
@export var option_chapters: OptionButton
@export var search_input: LineEdit
# Optional button, based on search type
@export var option_verses: OptionButton 
var search_scope:Types.SearchScope = Types.SearchScope.ALL_SCRIPTURE
#endregion 

#region range
@export_group("Search Range Destination")
@export var option_to_books: OptionButton 
@export var option_to_chapters: OptionButton 
@export var option_to_verses: OptionButton 
@export var button_range_search: Button 
#endregion 

func _ready():
	option_scope.item_selected.connect(set_scope)
	check_button_search_type.toggled.connect(change_search_mode)
	
	# When options selected, update other options.
	option_translation.item_selected.connect(populate_book_options)
	option_translation.item_selected.connect(populate_to_books_options)

	option_books.item_selected.connect(populate_book_chapters)
	option_chapters.item_selected.connect(populate_chapter_verses)
	option_to_books.item_selected.connect(populate_to_books_chapters)
	option_to_chapters.item_selected.connect(populate_to_chapter_verses)

	search_input.text_submitted.connect(search)
	button_range_search.pressed.connect(search)

	reset_scope_options()
	reset_translation_options()
	reset_book_options()
	reset_chapter_options()

	populate_translation_options()
	populate_book_options()
	populate_book_chapters()
	populate_to_books_options()
	
	setup_initial_search_state()

## Initial setup
func setup_initial_search_state():
	check_button_search_type.set_pressed(true)
	

## Toggles the search mode. 
func change_search_mode(on:bool):
	if is_search_mode():
		margin_container_search.show()
		option_verses.hide()
		h_box_container_range.hide()
	else:
		margin_container_search.hide()
		option_verses.show()
		h_box_container_range.show()

## Returns true if the search mode is active, false if range mode is active.
func is_search_mode():
	return check_button_search_type.is_pressed()

#region Main Search
## Populates the translation options based on the search scope.
func populate_translation_options(index:int = 0):
	reset_translation_options()
	var translations = ScriptureService.get_all_translations()
	match search_scope:
		Types.SearchScope.ALL_SCRIPTURE:
			for translation in translations:
				option_translation.add_item(translation["translation_abbr"], translation["id"])
		Types.SearchScope.COMMON_CANNONICAL:
			for translation in translations:
				if translation["translation_abbr"] != "scrollmapper":
					option_translation.add_item(translation["translation_abbr"], translation["id"])
		Types.SearchScope.EXTRA_CANNONICAL:
			for translation in translations:
				if translation["translation_abbr"] == "scrollmapper":
					option_translation.add_item(translation["translation_abbr"], translation["id"])
		_:
			for translation in translations:
				option_translation.add_item(translation["translation_abbr"], translation["id"])

## Populates the book options based on the selected translation.
func populate_book_options(index:int = 0):
	reset_book_options()
	var selected_translation_id = option_translation.get_selected_id()
	if selected_translation_id < 0:
		return
	var translation:String = ScriptureService.get_translation_by_id(selected_translation_id)["translation_abbr"]
	var books = ScriptureService.get_all_books(translation)

	for book in books:
		option_books.add_item(book["book_name"], book["id"])
	
	# Jumpstart the chapters
	populate_book_chapters()

## Populates the chapter options based on the selected book.
func populate_book_chapters(index:int = 0):
	reset_chapter_options()
	var selected_translation_id = option_translation.get_selected_id()
	var selected_book_id = option_books.get_selected_id()
	var book = ScriptureService.get_book_by_id(selected_translation_id, selected_book_id)
	if book.is_empty():
		return
	var chapters = ScriptureService.get_all_chapter_numbers_in_book(book["translation"], book["book_name"])

	for chapter in chapters["chapters"]:
		option_chapters.add_item(str(chapter), chapter)

## Populates the verse options based on the selected book and chapter.
func populate_chapter_verses(index:int = 0):
	reset_verse_options()
	var selected_translation_id = option_translation.get_selected_id()
	var selected_book_id = option_books.get_selected_id()
	var selected_chapter = option_chapters.get_selected_id()
	var book = ScriptureService.get_book_by_id(selected_translation_id, selected_book_id)
	if book.is_empty():
		return
	var verses = ScriptureService.get_all_verse_numbers_in_chapter(book["translation"], book["book_name"], selected_chapter)
	for verse in verses["verses"]:
		option_verses.add_item(str(verse), verse)

## Resets the scope options.
func reset_scope_options():
	option_scope.clear()
	option_scope.add_item("All Scripture")
	option_scope.add_item("Common-Cannonical")
	option_scope.add_item("Extra-Cannonical")

## Resets the translation options.
func reset_translation_options():
	option_translation.clear()
	#option_translation.add_item("-")

## Resets the book options.
func reset_book_options():
	option_books.clear()
	option_books.add_item("-")
	reset_chapter_options()

## Resets the chapter options.
func reset_chapter_options():
	option_chapters.clear()
	option_chapters.add_item("-")
	reset_verse_options()

## Resets the verse options.
func reset_verse_options():
	option_verses.clear()
	option_verses.add_item("-")
#endregion

#region Search Range
## Populates the book options based on the selected translation.
func populate_to_books_options(index:int = 0):
	reset_to_book_options()
	var selected_translation_id = option_translation.get_selected_id()
	if selected_translation_id < 0:
		return
	var translation:String = ScriptureService.get_translation_by_id(selected_translation_id)["translation_abbr"]
	var books = ScriptureService.get_all_books(translation)

	for book in books:
		option_to_books.add_item(book["book_name"], book["id"])
	
	# Jumpstart the chapters
	populate_to_books_chapters()

## Populates the to-chapter options based on the selected to-book.
func populate_to_books_chapters(index:int = 0):
	reset_to_chapter_options()
	var selected_translation_id = option_translation.get_selected_id()
	var selected_book_id = option_to_books.get_selected_id()
	var book = ScriptureService.get_book_by_id(selected_translation_id, selected_book_id)
	if book.is_empty():
		return
	var chapters = ScriptureService.get_all_chapter_numbers_in_book(book["translation"], book["book_name"])

	for chapter in chapters["chapters"]:
		option_to_chapters.add_item(str(chapter), chapter)

## Populates the to-verse options based on the selected to-book and to-chapter.
func populate_to_chapter_verses(index:int = 0):
	reset_to_verse_options()
	var selected_translation_id = option_translation.get_selected_id()
	var selected_book_id = option_to_books.get_selected_id()
	var selected_chapter = option_to_chapters.get_selected_id()
	var book = ScriptureService.get_book_by_id(selected_translation_id, selected_book_id)
	if book.is_empty():
		return
	var verses = ScriptureService.get_all_verse_numbers_in_chapter(book["translation"], book["book_name"], selected_chapter)

	for verse in verses["verses"]:
		option_to_verses.add_item(str(verse), verse)

## Resets the to-book options.
func reset_to_book_options():
	option_to_books.clear()
	option_to_books.add_item("-")
	reset_to_chapter_options()

## Resets the to-chapter options.
func reset_to_chapter_options():
	option_to_chapters.clear()
	option_to_chapters.add_item("-")
	reset_to_verse_options()

## Resets the to-verse options.
func reset_to_verse_options():
	option_to_verses.clear()
	option_to_verses.add_item("-")
#endregion

#region scope management
## Sets the search scope based on the selected index.
func set_scope(index:int):
	var scope = index
	reset_all_options()
	match scope:
		0:
			search_scope = Types.SearchScope.ALL_SCRIPTURE
		1:
			search_scope = Types.SearchScope.COMMON_CANNONICAL
		2:
			search_scope = Types.SearchScope.EXTRA_CANNONICAL
		_:
			search_scope = Types.SearchScope.ALL_SCRIPTURE
	option_scope.select(index)
	populate_translation_options()
	populate_book_options()
	populate_to_books_options()

## Resets all options.
func reset_all_options():
	reset_scope_options()
	reset_translation_options()
	reset_book_options()
	reset_chapter_options()
	reset_verse_options()
	reset_to_book_options()
	reset_to_chapter_options()
	reset_to_verse_options()
#endregion

#region search mechanism

## Initiates a search using ScriptureService.gd 
func search(text:String = ""):
	if is_search_mode():
		search_scripture_text(text)
	else:
		search_scripture_range()

## Initiates search for scriptures containing text.
func search_scripture_text(text:String):
	var scope:Types.SearchScope = search_scope
	var translation_text = option_translation.get_text()
	var book_text = option_books.get_text()
	var chapter = int(option_chapters.get_text())

	# Default text to empty if "-"
	if translation_text == "-":
		translation_text = ""
	if book_text == "-":
		book_text = ""

	# Default integers to -1 if they are 0
	if chapter == 0:
		chapter = -1

	ScriptureService.initiate_text_search(scope, translation_text, text, book_text, chapter)

## Initiates search for scriptures within a range.
func search_scripture_range():
	var scope:Types.SearchScope = search_scope
	var translation_text = option_translation.get_text()
	var book_text = option_books.get_text()
	var chapter = int(option_chapters.get_text())
	var verse = int(option_verses.get_text())
	var to_book_text = option_to_books.get_text()
	var to_chapter = int(option_to_chapters.get_text())
	var to_verse = int(option_to_verses.get_text())

	# Default integers to -1 if they are 0
	if chapter == 0:
		chapter = -1
	if verse == 0:
		verse = -1
	if to_chapter == 0:
		to_chapter = -1
	if to_verse == 0:
		to_verse = -1

	# Default text to empty if "-"
	if translation_text == "-":
		translation_text = ""
	if book_text == "-":
		book_text = ""
	if to_book_text == "-":
		to_book_text = ""
	ScriptureService.initiate_range_search(translation_text, book_text, chapter, verse, to_book_text, to_chapter, to_verse)

## Getter for search scope
func get_search_scope() -> Types.SearchScope:
	return search_scope

## Getter for translation abbreviation
func get_translation_abbrev() -> String:
	var translation_text = option_translation.get_item_text(option_translation.get_item_index( option_translation.get_selected_id()))
	return translation_text
