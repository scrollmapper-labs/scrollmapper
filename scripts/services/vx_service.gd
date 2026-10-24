extends Node

## This is a service that will be used to relay information regarding the 
## vx system. See res://scenes/modules/vx/ 


## Will get a graph if the id is supplied. If id is not supplied, a new graph will
## be created and returned.
func get_or_create_graph(id:int = -1) -> Dictionary:
	var vx_graph_model:VXGraphModel = VXGraphModel.new()
	var vx_graph_data: = get_graph_data_template()

	if id > 0:
		var graph_data = vx_graph_model.get_graph_by_id(id)
		if graph_data.size() > 0:
			var results:Dictionary = graph_data
			vx_graph_data["id"] = results["id"]
			vx_graph_data["graph_name"] = results["graph_name"]
			vx_graph_data["graph_description"] = results["graph_description"]
	else:
		vx_graph_model.save()
		vx_graph_data["id"] = vx_graph_model.id
		vx_graph_data["graph_name"] = vx_graph_model.graph_name
		vx_graph_data["graph_description"] = vx_graph_model.graph_description

	return vx_graph_data

## Gets the last used graph from the meta data.
func get_last_used_graph() -> Dictionary:
	var vx_graph_model:VXGraphModel = VXGraphModel.new()
	var last_graph_id:Dictionary = MetaService.get_meta_data("last_used_graph_id")
	var results:Dictionary = vx_graph_model.get_graph_by_id(int(last_graph_id.get("id", -1)))
	return results

## This function saves a graph.
## The graph_data dictionary should have the following keys:
## - id
## - graph_name
## - graph_description
## - nodes
## - connections
## It first creates the actual graph if it does not exist. 
## Then it creates the nodes and connections. Finally, it creates the
## graph-node and graph-connection relationships.
func save_graph(graph_data:Dictionary) -> void:
	if not graph_data.has("id") or not is_valid_graph_export(graph_data):
		print("Invalid graph data; saved graph was preserved.")
		return
	# First, create the graph...
	if graph_data.has("id") and graph_data.has("graph_name") and graph_data.has("graph_description"):
		clear_graph(graph_data["id"])
		var vx_graph_model:VXGraphModel = VXGraphModel.new()
		vx_graph_model.id = graph_data["id"]
		vx_graph_model.graph_name = graph_data["graph_name"]
		vx_graph_model.graph_description = graph_data["graph_description"]
		graph_data["id"] = vx_graph_model.save()

		MetaService.set_meta_data("last_used_graph_id", {"id": vx_graph_model.id})
	else:
		print("Error: graph_data dictionary is missing required keys.")

	# Next, create the nodes
	if graph_data.has("nodes"):
		for node_data in graph_data["nodes"]:
			save_node(node_data)
	else:
		print("Error: graph_data dictionary is missing nodes key.")

	# Now, create the connections
	if graph_data.has("connections"):
		for connection_data in graph_data["connections"]:
			save_connection(connection_data)
	else:
		print("Error: graph_data dictionary is missing connections key.")

	# Finally, create the graph-node and graph-connection relationships
	save_graph_nodes(graph_data)
	save_graph_connections(graph_data)

## Saves a node to the database.
func save_node(node_data:Dictionary) -> void:
	if node_data.has("id") and node_data.has("book") and node_data.has("chapter") and node_data.has("verse") and node_data.has("translation"):
		var vx_node_model:VXNodeModel = VXNodeModel.new()
		vx_node_model.id = node_data["id"]
		vx_node_model.book = node_data["book"]
		vx_node_model.chapter = node_data["chapter"]
		vx_node_model.verse = node_data["verse"]
		vx_node_model.translation = node_data["translation"]
		vx_node_model.save()
	else:
		print("Error: node_data dictionary is missing required keys.")

## Clears all nodes and connections by graph id.
func clear_graph(graph_id: int) -> void:
	var vx_graph_node_model: VXGraphNodeModel = VXGraphNodeModel.new()
	var vx_graph_connection_model: VXGraphConnectionModel = VXGraphConnectionModel.new()

	# Delete graph-node relationships
	var graph_nodes = vx_graph_node_model.get_nodes_by_graph(graph_id)
	for graph_node in graph_nodes:
		vx_graph_node_model.graph_id = graph_id
		vx_graph_node_model.node_id = graph_node["node_id"]
		vx_graph_node_model.delete()

	# Delete graph-connection relationships
	var graph_connections = vx_graph_connection_model.get_connections_by_graph(graph_id)
	for graph_connection in graph_connections:
		vx_graph_connection_model.graph_id = graph_id
		vx_graph_connection_model.connection_id = graph_connection["connection_id"]
		vx_graph_connection_model.delete()

## Saves a connection to the database.
func save_connection(connection_data:Dictionary) -> void:
	if connection_data.has("id") and connection_data.has("text") and connection_data.has("start_node") and connection_data.has("end_node") and connection_data.has("is_parallel"):
		var vx_connection_model:VXConnectionModel = VXConnectionModel.new()
		vx_connection_model.id = connection_data["id"]
		vx_connection_model.text = connection_data["text"]
		vx_connection_model.start_node_id = connection_data["start_node"]
		vx_connection_model.end_node_id = connection_data["end_node"]
		vx_connection_model.is_parallel = connection_data["is_parallel"]
		vx_connection_model.save()
	else:
		print("Error: connection_data dictionary is missing required keys.")

## Saves the graph-node relationships to the database.
## These are the many-to-many relationships linking the unique
## vx_nodes and vx_graphs to database
func save_graph_nodes(graph_data:Dictionary) -> void:
	if graph_data.has("id") and graph_data.has("nodes"):
		for node_data in graph_data["nodes"]:
			var vx_graph_node_model:VXGraphNodeModel = VXGraphNodeModel.new()
			vx_graph_node_model.graph_id = graph_data["id"]
			vx_graph_node_model.node_id = node_data["id"]
			vx_graph_node_model.position_x = node_data["position_x"]
			vx_graph_node_model.position_y = node_data["position_y"]
			vx_graph_node_model.top_sockets_amount = node_data["top_sockets_amount"]
			vx_graph_node_model.bottom_sockets_amount = node_data["bottom_sockets_amount"]
			vx_graph_node_model.left_sockets_amount = node_data["left_sockets_amount"]
			vx_graph_node_model.right_sockets_amount = node_data["right_sockets_amount"]
			vx_graph_node_model.save()
	else:
		print("Error: graph_data dictionary is missing required keys or nodes.")

## Saves the graph-connection relationships to the database.
## These are the many-to-many relationships linking the unique
## vx_connections and vx_graphs to database
func save_graph_connections(graph_data:Dictionary) -> void:
	if graph_data.has("id") and graph_data.has("connections"):
		for connection_data in graph_data["connections"]:
			var vx_graph_connection_model:VXGraphConnectionModel = VXGraphConnectionModel.new()
			vx_graph_connection_model.graph_id = graph_data["id"]
			vx_graph_connection_model.connection_id = connection_data["id"]
			vx_graph_connection_model.start_node_side = connection_data["start_node_side"]
			vx_graph_connection_model.end_node_side = connection_data["end_node_side"]
			vx_graph_connection_model.start_node_socket_index = connection_data["start_socket_index"]
			vx_graph_connection_model.end_node_socket_index = connection_data["end_socket_index"]
			vx_graph_connection_model.save()
	else:
		print("Error: graph_data dictionary is missing required keys or connections.")

## Gets the full saved graph data including nodes, connections, and relationships.
func get_saved_graph(id: int) -> Dictionary:
	var vx_graph_model: VXGraphModel = VXGraphModel.new()
	var vx_graph_node_model: VXGraphNodeModel = VXGraphNodeModel.new()
	var vx_graph_connection_model: VXGraphConnectionModel = VXGraphConnectionModel.new()
	var graph_data: Dictionary = vx_graph_model.get_graph_by_id(id)

	if graph_data.size() == 0:
		print("Error: No graph found with the provided id.")
		return {}

	var full_graph_data: Dictionary = get_graph_data_template()
	full_graph_data["id"] = graph_data["id"]
	full_graph_data["graph_name"] = graph_data["graph_name"]
	full_graph_data["graph_description"] = graph_data["graph_description"]

	# Get nodes
	var vx_node_model: VXNodeModel = VXNodeModel.new()
	var nodes = vx_node_model.get_nodes_by_graph(id)
	for node in nodes:
		full_graph_data["nodes"].append(node)

	# Get connections
	var vx_connection_model: VXConnectionModel = VXConnectionModel.new()
	var connections = vx_connection_model.get_connections_by_graph(id)
	for connection in connections:
		full_graph_data["connections"].append(connection)

	# Get graph-node relationships
	var graph_nodes = vx_graph_node_model.get_nodes_by_graph(id)
	for graph_node in graph_nodes:
		full_graph_data["graph_nodes"].append(graph_node)

	# Get graph-connection relationships
	var graph_connections = vx_graph_connection_model.get_connections_by_graph(id)
	for graph_connection in graph_connections:
		full_graph_data["graph_connections"].append(graph_connection)
	return full_graph_data

## Converts a saved JSON string to a graph dictionary.
## This is used in vx_graph import_graph_from_json function.
func get_saved_graph_from_json(json_string: String) -> Dictionary:
	var vx_graph_tmp:VXGraphModel = VXGraphModel.new()
	var next_graph_id:int = vx_graph_tmp.get_next_graph_id()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("JSON Parse Error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}

	var graph_data = json.data
	if not is_valid_graph_export(graph_data):
		push_error("Unexpected data format in JSON string.")
		return {}

	var full_graph_data: Dictionary = get_graph_data_template()
	full_graph_data["id"] = next_graph_id
	full_graph_data["graph_name"] = graph_data["graph_name"]
	full_graph_data["graph_description"] = graph_data["graph_description"]	

	for node_data in graph_data["nodes"]:
		var node:Dictionary = {
			"id": int(node_data["id"]),
			"book": node_data["book"],
			"chapter": int(node_data["chapter"]),
			"verse": int(node_data["verse"]),
			"translation": node_data["translation"]
		}
		full_graph_data["nodes"].append(node)

	for connection_data in graph_data["connections"]:
		var connection:Dictionary = {
			"id": int(connection_data["id"]),
			"text": connection_data["text"],
			"start_node_id": int(connection_data["start_node"]),
			"end_node_id": int(connection_data["end_node"]),
			"is_parallel": int(connection_data["is_parallel"])
		}
		full_graph_data["connections"].append(connection)

	for graph_node_data in graph_data["nodes"]:
		var graph_node:Dictionary = {
			"node_id": int(graph_node_data["id"]),
			"position_x": float(graph_node_data["position_x"]),
			"position_y": float(graph_node_data["position_y"]),
			"top_sockets_amount": int(graph_node_data["top_sockets_amount"]),
			"bottom_sockets_amount": int(graph_node_data["bottom_sockets_amount"]),
			"left_sockets_amount": int(graph_node_data["left_sockets_amount"]),
			"right_sockets_amount": int(graph_node_data["right_sockets_amount"])
		}
		full_graph_data["graph_nodes"].append(graph_node)

	for graph_connection_data in graph_data["connections"]:
		var graph_connection:Dictionary = {
			"connection_id": int(graph_connection_data["id"]),
			"start_node_side": graph_connection_data["start_node_side"],
			"end_node_side": graph_connection_data["end_node_side"],
			"start_node_socket_index": int(graph_connection_data["start_socket_index"]),
			"end_node_socket_index": int(graph_connection_data["end_socket_index"])
		}
		full_graph_data["graph_connections"].append(graph_connection)
	return full_graph_data

## Creates a new empty graph and returns its data.
func create_new_empty_graph() -> Dictionary:
	var vx_graph: VXGraphModel = VXGraphModel.new()
	vx_graph.graph_name = "New Graph"
	vx_graph.graph_description = "This is a new graph."
	vx_graph.id = vx_graph.save() # Save the new graph to the database and get its ID
	var graph_data:Dictionary = get_graph_data_template()
	graph_data["id"] = vx_graph.id
	graph_data["graph_name"] = vx_graph.graph_name
	graph_data["graph_description"] = vx_graph.graph_description
	return graph_data

func delete_graph(id:int) -> void:
	var vx_graph_model: VXGraphModel = VXGraphModel.new()
	var vx_graph_node_model: VXGraphNodeModel = VXGraphNodeModel.new()
	var vx_graph_connection_model: VXGraphConnectionModel = VXGraphConnectionModel.new()

	# Delete graph-node relationships
	var graph_nodes = vx_graph_node_model.get_nodes_by_graph(id)
	for graph_node in graph_nodes:
		vx_graph_node_model.graph_id = id
		vx_graph_node_model.node_id = graph_node["node_id"]
		vx_graph_node_model.delete()

	# Delete graph-connection relationships
	var graph_connections = vx_graph_connection_model.get_connections_by_graph(id)
	for graph_connection in graph_connections:
		vx_graph_connection_model.graph_id = id
		vx_graph_connection_model.connection_id = graph_connection["connection_id"]
		vx_graph_connection_model.delete()

	# Delete the graph itself
	vx_graph_model.id = id
	vx_graph_model.delete()

	# Update the last used graph
	var last_used_graph_id:Dictionary = MetaService.get_meta_data("last_used_graph_id")
	if last_used_graph_id.has("id") and last_used_graph_id["id"] == id:
		MetaService.set_meta_data("last_used_graph_id", {"id": -1})

## Gets a list of all graphs.
func get_graph_list() -> Array:
	var vx_graph_model: VXGraphModel = VXGraphModel.new()
	var graphs = vx_graph_model.get_all_graphs()
	return graphs

func get_graph_node_amount(id:int) -> int:
	var vx_graph: VXGraphModel = VXGraphModel.new()
	vx_graph.id = id
	return vx_graph.get_node_amount()

## Gets the full saved graph data including nodes, connections, and relationships.
func get_graph_data_template() -> Dictionary:
	return {
		"id": -1,
		"graph_name": "Scripture Map",
		"graph_description": "",
		"nodes": [],
		"connections": [], 
		"graph_nodes": [],
		"graph_connections": []
	}


func is_valid_graph_export(data:Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["graph_name", "graph_description"]:
		if not data.get(key) is String:
			return false
	for key in ["nodes", "connections"]:
		if not data.get(key) is Array:
			return false
	var node_ids:Dictionary = {}
	for node in data["nodes"]:
		if not node is Dictionary:
			return false
		for key in ["book", "translation"]:
			if not node.get(key) is String:
				return false
		for key in ["id", "chapter", "verse", "position_x", "position_y", "top_sockets_amount", "bottom_sockets_amount", "left_sockets_amount", "right_sockets_amount"]:
			if not (node.get(key) is int or node.get(key) is float):
				return false
		if node_ids.has(int(node["id"])):
			return false
		node_ids[int(node["id"])] = true
	for connection in data["connections"]:
		if not connection is Dictionary or not connection.get("text") is String:
			return false
		for key in ["id", "start_node", "end_node", "start_node_side", "end_node_side", "start_socket_index", "end_socket_index"]:
			if not (connection.get(key) is int or connection.get(key) is float):
				return false
		if not connection.has("is_parallel") or not node_ids.has(int(connection["start_node"])) or not node_ids.has(int(connection["end_node"])):
			return false
	return true
