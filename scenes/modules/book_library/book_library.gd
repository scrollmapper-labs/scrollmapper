extends Control

class_name BookLibrary

const BOOK_LISTING = preload("res://scenes/modules/book_library/grid_elements/book_listing.tscn")
const DIVIDER = preload("res://scenes/modules/book_library/grid_elements/divider.tscn")

## The main book list container. 
@export var book_list: VBoxContainer
@export var scroll_list:Array[Texture]
## Button to queue the update from a list online at github 
## https://raw.githubusercontent.com/scrollmapper/book_list/refs/heads/main/book_list.json
@export var update_list_button: Button

## Syncronizes the database to chosen llist options.
@export var syncronize_button: Button 

## Close the window. 
@export var done_button: Button

var listings:Dictionary = {}

var book_list_items:Array[BookListing] = []

var install_queue:Array[BookListing] = []
var install_queue_next_index = 0

var is_processing_book:bool = false
signal book_process_complete
signal install_queue_processed

func _ready() -> void:
	update_list_button.pressed.connect(_on_update_list_button_pressed)
	syncronize_button.pressed.connect(_on_syncronize_button_pressed)
	done_button.pressed.connect(_on_done_button_pressed)
	install_queue_processed.connect(do_install_queue)
	LibraryManager.update_source_list_ended.connect(update_lists)
	update_lists()

func update_lists():
	for child in book_list.get_children():
		child.queue_free()	
	listings.clear()
	var source_list:SourceReferenceList = LibraryManager.source_reference_list
	for biblical_source:SourceReference in source_list.get_extrabiblical_sources():
		add_listing(biblical_source)
	for biblical_source:SourceReference in source_list.get_biblical_sources():
		add_listing(biblical_source)

func add_listing(source_reference:SourceReference) -> void:
	var new_book_listing:BookListing = BOOK_LISTING.instantiate()
	new_book_listing.book = source_reference.book
	new_book_listing.title = source_reference.title
	new_book_listing.language = source_reference.language
	new_book_listing.content_type = source_reference.content_type
	new_book_listing.set_current_status()
	book_list.add_child(new_book_listing)
	listings[new_book_listing.book] = new_book_listing
	var icon:Texture2D = get_scroll_icon(new_book_listing.book)
	new_book_listing.set_scroll_icon(icon)
	var divider:Panel = DIVIDER.instantiate()
	book_list.add_child(divider)

func _on_update_list_button_pressed():
	LibraryManager.update_source_list()

func _on_syncronize_button_pressed():
	syncronize_book_selections()
	
func _on_done_button_pressed():
	GameManager.load_level("HOME")


func syncronize_book_selections():
	if is_processing_book:
		return
	install_queue.clear()
	install_queue_next_index = 0
	for book_listing in listings.keys():
		if is_processing_book:
			await book_process_complete		
		book_listing = listings[book_listing]
		if not book_listing.is_installed and book_listing.is_selected:
			print("Installing " + book_listing.book)
			install_queue.append(book_listing)
		elif book_listing.is_installed and !book_listing.is_selected:
			print("Uninstalling " + book_listing.book)
			do_uninstall_book_process(book_listing)
	do_install_queue()

	
func do_install_queue() -> void:
	if install_queue == []:
		return
	var next_install:BookListing
	if install_queue_next_index < install_queue.size():
		next_install = install_queue[install_queue_next_index]
	else:
		return
	install_queue_next_index += 1
	do_install_book_process(next_install)

func do_install_book_process(book_listing:BookListing):
	move_progress_dialog_to_front(true)
	is_processing_book = true
	syncronize_button.disabled = true
	update_list_button.disabled = true
	done_button.disabled = true
	var install_book:InstallBook = InstallBook.new(book_listing.book)
	if !install_book.is_book_file_available():
		if ResourceDownloader.instance.retrieve_book(book_listing.book):
			await ResourceDownloader.instance.download_process_complete
		
	var installed:bool = await install_book.install()

	is_processing_book = false
	syncronize_button.disabled = false
	update_list_button.disabled = false
	done_button.disabled = false
	book_process_complete.emit()
	book_listing.is_installed = installed
	book_listing.set_current_status()
	move_progress_dialog_to_front(false)
	install_book.free()
	install_queue_processed.emit()

func move_progress_dialog_to_front(front:bool = true) -> void:
	if front:
		DialogueManager.reparent_progress_dialog(self)
	else:
		DialogueManager.reparent_progress_dialog()

func do_uninstall_book_process(book_listing:BookListing):
	is_processing_book = true
	if book_listing.content_type == "extrabiblical":
		ScriptureService.uninstall_book("scrollmapper", book_listing.title)
	if book_listing.content_type == "bible":
		ScriptureService.uninstall_translation(book_listing.book)

	is_processing_book = false
	syncronize_button.disabled = false
	update_list_button.disabled = false
	done_button.disabled = false
	book_process_complete.emit()
	book_listing.is_installed = false
	book_listing.set_current_status()

## Gets a specific random (lol) scroll icon based on a seed string.
func get_scroll_icon(seed_string:String) -> Texture2D:
	seed(seed_string.hash()+1)
	if scroll_list.size() == 0:
		return null
	var random_index = randi() % scroll_list.size()
	return scroll_list[random_index]
