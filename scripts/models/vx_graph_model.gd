extends BaseModel

## This is the base model for vx_graph.

class_name VXGraphModel

#region Main variables...
var id: int = 0
var graph_name: String = ""
var graph_description: String = ""
#endregion

func _init():
	super._init()
	create_table()

func get_create_table_query() -> String:
	return """
	CREATE TABLE IF NOT EXISTS vx_graphs (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		graph_name TEXT,
		graph_description TEXT
	);
	"""

func save() -> int:
	# Check if graph already exists
	var query = "SELECT id FROM vx_graphs WHERE id = ?;"
	var result = get_results(query, [id])
	
	if result.size() > 0:
		# Update existing graph
		var update_query = "UPDATE vx_graphs SET graph_name = ?, graph_description = ? WHERE id = ?;"
		execute_query(update_query, [graph_name, graph_description, id])
		return result[0]["id"]
	else:
		var insert_query = "INSERT INTO vx_graphs (graph_name, graph_description) VALUES (?, ?);"
		execute_query(insert_query, [graph_name, graph_description])
		id = get_last_inserted_id()
		return id

func get_graph_by_id(graph_id: int) -> Dictionary:
	var query = "SELECT * FROM vx_graphs WHERE id = ?;"
	var result = get_results(query, [graph_id])
	
	if result.size() > 0:
		var row = result[0]
		id = row["id"]
		graph_name = row["graph_name"]
		graph_description = row["graph_description"]
		return result[0]
	else:
		return {}

func get_all_graphs():
	var query = "SELECT * FROM vx_graphs;"
	return get_results(query)

func get_node_amount() -> int:
	var relationships = VXGraphNodeModel.new()
	var query = "SELECT COUNT(*) FROM vx_graph_nodes WHERE graph_id = ?;"
	var result = get_results(query, [id])
	return result[0]["COUNT(*)"]

func delete():
	var query = "DELETE FROM vx_graphs WHERE id = ?;"
	print("Deleting graph with id: ", id)
	execute_query(query, [id])

func get_next_graph_id() -> int:
	var query = "SELECT MAX(id) AS max_id FROM vx_graphs;"
	var result = get_results(query)
	
	if result.size() > 0 and result[0]["max_id"] != null:
		return result[0]["max_id"] + 1
	else:
		return 1
