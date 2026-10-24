extends RefCounted

class_name BaseModel

const CMD_STYLE_APP = "res://addons/cmd/interface/styles/cmd_styles/cmd_style_app.tres"
const CMD_STYLE_EDITOR = "res://addons/cmd/interface/styles/cmd_styles/cmd_style_editor.tres"

var cmd_style: CmdStyle = null

var db: SQLite = null

func _init() -> void:
	if not Engine.is_editor_hint():
		cmd_style = load(CMD_STYLE_APP)
	else:
		cmd_style = load(CMD_STYLE_EDITOR)
		
	if not Engine.is_editor_hint():
		# We are not in editor.
		db = GlobalDB.get_db()
		
	if Engine.is_editor_hint():
		# We are in editor.		
		db = EditorDB.db
		
func execute_query(query: String, params: Array = []):
	db.query_with_bindings(query, params)
	

func get_results(query: String, params: Array = []):
	var succeeded:bool = db.query_with_bindings(query, params)
	db.verbosity_level = 0
	var results = []
	for result in db.query_result:
		results.append(result)
	if not succeeded:
		print("Error executing query: %s" % db.error_message)

	return results

func create_table():
	var create_table_query = get_create_table_query()
	execute_query(create_table_query)

func get_create_table_query() -> String:
	return ""  # To be overridden by subclasses

func get_last_inserted_id() -> int:
	var query = "SELECT last_insert_rowid() as id;"
	var result = get_results(query)
	if result.size() > 0:
		return result[0]["id"]
	else:
		return -1
