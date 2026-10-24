extends Resource

class_name DataManager

## The source list is a JSON file that contains a list of books and their metadata.
const source_list: String = "https://raw.githubusercontent.com/scrollmapper/book_list/refs/heads/main/book_list.json"

## Main scrollmapper data directory
const scrollmapper_data_dir:String = "scrollmapper_data"

## Create initial directories
func create_initial_directories():
	var dir = DirAccess.open(OS.get_user_data_dir())
	dir.make_dir_recursive(get_scrollmapper_data_dir())
	dir.make_dir_recursive(get_scrollmapper_sources_dir())
	dir.make_dir_recursive(get_scrollmapper_user_dir())
	dir.make_dir_recursive(get_scrollmapper_db_dir())


## Create initial database
func create_initial_database(overwrite: bool = false):
	var db_path = get_scrollmapper_db_dir().path_join("database.sqlite")
	if not overwrite and FileAccess.file_exists(db_path):
		return
	
	var default_db_path:String = get_executable_sources_dir().path_join("database.sqlite")

	if OS.has_feature("editor"):
		## We are running from the editor. So copy from res:// instead.
		default_db_path = "res://sources/database.sqlite"

	if FileAccess.file_exists(default_db_path):
		copy(default_db_path, db_path)

## Create initial book list
func create_initial_book_list(overwrite: bool = false):
	var book_list_path = get_source_list_path()
	if not overwrite and FileAccess.file_exists(book_list_path):
		return

	var default_book_list_path:String = get_executable_sources_dir().path_join("book_list.json")

	if OS.has_feature("editor"):
		## We are running from the editor. So copy from res:// instead.
		default_book_list_path = "res://sources/book_list.json"
	print(default_book_list_path)
	if FileAccess.file_exists(default_book_list_path):
		copy(default_book_list_path, book_list_path)
	else:
		print("Book list not found...")

## Main scrollmapper data directory
func get_scrollmapper_data_dir() -> String:
	var data_dir:String = OS.get_user_data_dir()
	data_dir = data_dir.path_join(scrollmapper_data_dir)
	return data_dir

## Get the sources directory in the executable directory.
## Note that this is distinct from get_scrollmapper_sources_dir(),
## which returns the sources directory in the user-data directory area Godot uses.
## The get_executable_sources_dir() function was initially created to get default data
## from the install directory to populate the default data of user-data directories.
func get_executable_sources_dir() -> String:
	var executable_dir:String = OS.get_executable_path().get_base_dir()
	var sources_dir:String = executable_dir.path_join("sources")
	return sources_dir

## Sources directory, where the source list is stored books are downloaded 
## Distinct from get_executable_sources_dir(), which returns the sources directory in the executable directory. 
func get_scrollmapper_sources_dir() -> String:
	var data_dir:String = get_scrollmapper_data_dir()
	data_dir = data_dir.path_join("sources")
	return data_dir

## User directory, where user data is stored
func get_scrollmapper_user_dir() -> String:
	var data_dir:String = get_scrollmapper_data_dir()
	data_dir = data_dir.path_join("user")
	return data_dir

## Database directory, where SQLite database is stored
func get_scrollmapper_db_dir() -> String:
	var data_dir:String = get_scrollmapper_data_dir()
	data_dir = data_dir.path_join("database")
	return data_dir

## Get the path to the source list
func get_source_list_path() -> String:
	var data_dir:String = get_scrollmapper_sources_dir()
	var book_list = data_dir.path_join("book_list.json")
	return book_list

## Get the path to a book
func get_book_path(book_name:String) -> String:
	var data_dir:String = get_scrollmapper_sources_dir()
	var book_path = data_dir.path_join(book_name + ".json")
	return book_path


## Copies a given file from the directories folders to the export directory. 
func copy(source_file: String, destination_file: String) -> void:
	var content = load_from_file(source_file)
	save_to_file(destination_file, content)

## Saves a given content to a file.
func save_to_file(destination_file:String, content):
	var file = FileAccess.open(destination_file, FileAccess.WRITE)
	file.store_buffer(content)

## Loads a file from the given source file.
func load_from_file(source_file:String):
	var file = FileAccess.open(source_file, FileAccess.READ)
	var content = file.get_buffer(file.get_length())
	return content
