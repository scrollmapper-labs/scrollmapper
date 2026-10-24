@icon("res://images/icons/editor/ArrowDown.svg")
extends Node
class_name ResourceDownloader

signal download_complete(file_location:String)
signal download_failed()

@export var data_manager:DataManager

static var instance:ResourceDownloader = null
var http_request:HTTPRequest = null
var file_path:Types.DataDir = Types.DataDir.DATA
var file_name:String = "null"
var is_processing_request:bool = false
var last_download_succeeded:bool = false

signal download_process_started
signal download_process_complete

func _ready() -> void:
	if instance == null:
		instance = self		
	http_request = HTTPRequest.new()
	http_request.timeout = 30.0
	add_child(http_request)	
	http_request.request_completed.connect(_http_request_completed)

func retrieve_source_list() -> bool:
	if is_processing_request:
		return false
	file_name = "book_list.json"
	Command.print_to_console("Retrieving book_list.json from %s"%data_manager.source_list)
	return download_file(data_manager.source_list, Types.DataDir.SOURCES)
	
func retrieve_book(book_name:String) -> bool:
	if is_processing_request:
		return false
	var source_reference_list:SourceReferenceList = SourceReferenceList.new()
	file_name = book_name + ".json"
	var book_source:String = source_reference_list.get_book_source(book_name)
	if book_source.is_empty():
		Command.print_to_console("Book invalid. Run show_source_list in the Scrollmapper terminal to see which books are available.")
		return false
	Command.print_to_console("Getting book '%s' from %s"%[book_name, book_source])
	return download_file(book_source, Types.DataDir.SOURCES)
	
func download_file(file_url:String, file_path:Types.DataDir) -> bool:
	if is_processing_request:
		return false
	is_processing_request = true
	last_download_succeeded = false
	download_process_started.emit()
	self.file_path = file_path
	var error = http_request.request(file_url)
	if error != OK:
		_finish_download.call_deferred(false, "An error occurred in the HTTP request.")
	return true

func _http_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_finish_download(false, "Download failed (HTTP %s, result %s)." % [response_code, result])
		return
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_finish_download(false, "Downloaded file is not valid JSON.")
		return
	if file_name == "book_list.json":
		if not SourceReferenceList.is_valid_source_list(json.data):
			_finish_download(false, "Downloaded source list is invalid.")
			return
	elif not InstallBook.is_valid_book_data(json.data):
		_finish_download(false, "Downloaded book data is invalid.")
		return
	var sources_file_path = data_manager.get_scrollmapper_sources_dir().path_join(file_name)
	var temporary_path = sources_file_path + ".download"
	var file = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		_finish_download(false, "Cannot save downloaded file.")
		return
	file.store_buffer(body)
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK or DirAccess.rename_absolute(temporary_path, sources_file_path) != OK:
		_finish_download(false, "Cannot replace downloaded file.")
		return
	_finish_download(true, "Download complete at %s" % sources_file_path, sources_file_path)

func _finish_download(succeeded:bool, message:String, saved_path:String = "") -> void:
	last_download_succeeded = succeeded
	is_processing_request = false
	Command.print_to_console(message)
	if succeeded:
		download_complete.emit(saved_path)
	else:
		download_failed.emit()
	download_process_complete.emit()
