extends Node

## Manages the library of installed books. 
## Used by res://scenes/modules/book_library/book_library.gd

var source_reference_list:SourceReferenceList = null

signal update_source_list_started
signal update_source_list_ended

signal install_book_started(book_name: String)
signal install_book_ended(book_name: String)

signal download_book_started(book_name: String)
signal download_book_ended(book_name: String)

signal install_cross_references_started
signal install_cross_references_ended

func _ready() -> void:
	source_reference_list = SourceReferenceList.new()

## Updates the source list using the command from update_source_list.gd
func update_source_list():
	if not ResourceDownloader.instance.retrieve_source_list():
		return
	update_source_list_started.emit()
	await ResourceDownloader.instance.download_process_complete
	if ResourceDownloader.instance.last_download_succeeded:
		source_reference_list = SourceReferenceList.new()
	update_source_list_ended.emit()

## Installs a book using the command from install_book.gd
func install_book(book_name: String):
	var command_string = "install_book -b %s" % book_name
	Command.execute(command_string)

## Downloads a book using the command from download_book.gd
func download_book(book_name: String):
	if not ResourceDownloader.instance.retrieve_book(book_name):
		return
	print("Downloading book: %s" % book_name)
	await ResourceDownloader.instance.download_process_complete
	print("Download of %s complete." % book_name)

## Installs cross references using the command from install_cross_references.gd
func install_cross_references():
	var command_string = "install_cross_references"
	Command.execute(command_string)

## Emits the update_source_list_started signal
func emit_update_source_list_started():
	update_source_list_started.emit()

## Emits the update_source_list_ended signal
func emit_update_source_list_ended():
	update_source_list_ended.emit()

## Emits the install_book_started signal
func emit_install_book_started(book_name: String):
	install_book_started.emit(book_name)

## Emits the install_book_ended signal
func emit_install_book_ended(book_name: String):
	install_book_ended.emit(book_name)

## Emits the download_book_started signal
func emit_download_book_started(book_name: String):
	download_book_started.emit(book_name)

## Emits the download_book_ended signal
func emit_download_book_ended(book_name: String):
	download_book_ended.emit(book_name)

## Emits the install_cross_references_started signal
func emit_install_cross_references_started():
	install_cross_references_started.emit()

## Emits the install_cross_references_ended signal
func emit_install_cross_references_ended():
	install_cross_references_ended.emit()
