extends BaseExporter

## This class takes a VXGraph and exports it to Gephi format.
class_name ExporterVXGraphToJson

var graph_json: String
var save_path: String = ""

func _init(vx_graph: VXGraph, _save_path: String) -> void:
	save_path = _save_path
	set_export_data(vx_graph.get_full_graph_as_dictionary())
	var graph:Dictionary = vx_graph.get_full_graph_as_dictionary()
	graph_json = JSON.stringify(graph)
	
func export() -> void:
	# Save to File 
	save_to_file(graph_json)

func save_to_file(content: String) -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		Command.print_to_console("Could not write export: %s" % save_path)
		return
	file.store_string(content)
	file.close()
