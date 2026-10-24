extends BaseExporter
## This class takes the cross_reference database and exports it to Gephi format.
class_name ExporterCrossReferencesToGephi

var gephi_network: GephiNetwork
var save_path:String = ""
var version_dict:Dictionary = {}
var included_verse_meta:Array = []

func _init(_save_path:String, verse_meta_keys:Array=[]) -> void:
	save_path = _save_path
	included_verse_meta = verse_meta_keys
	version_dict = ScriptureService.get_versions_as_book_chapter_verse_dictionary(["KJV", "scrollmapper"])
	populate_export_data()
	gephi_network = GephiNetwork.new("2025-1-01", "Scrollmapper", "Cross References Export", export_data["nodes"], export_data["connections"], included_verse_meta)

func populate_export_data():
	var cross_references:Array = ScriptureService.get_all_cross_references_simple()
	export_data["nodes"] = []
	export_data["connections"] = []

	var nodes: Array = []
	var edges: Array = []
	var node_ids: Dictionary = {}
	var edge_id: int = 0

	for cross_reference in cross_references:
		var from_node_id:int = ScriptureService.get_scripture_id(cross_reference["from_book"], cross_reference["from_chapter"], cross_reference["from_verse"])
		var to_node_id:int = ScriptureService.get_scripture_id(cross_reference["to_book"], cross_reference["to_chapter_start"], cross_reference["to_verse_start"])

		var from_verse_data: Dictionary = get_verse_data("KJV", cross_reference["from_book"], cross_reference["from_chapter"], cross_reference["from_verse"])
		if from_verse_data.is_empty():
			from_verse_data = get_verse_data("scrollmapper", cross_reference["from_book"], cross_reference["from_chapter"], cross_reference["from_verse"])

		var to_verse_data: Dictionary = get_verse_data("KJV", cross_reference["to_book"], cross_reference["to_chapter_start"], cross_reference["to_verse_start"])
		if to_verse_data.is_empty():
			to_verse_data = get_verse_data("scrollmapper", cross_reference["to_book"], cross_reference["to_chapter_start"], cross_reference["to_verse_start"])

		var from_verse_hash:int = ScriptureService.get_verse_hash(cross_reference["from_book"], cross_reference["from_chapter"], cross_reference["from_verse"])
		var to_verse_hash:int = ScriptureService.get_verse_hash(cross_reference["to_book"], cross_reference["to_chapter_start"], cross_reference["to_verse_start"])

		if not node_ids.has(from_node_id):
			nodes.append({
				"id": from_node_id,
				"scripture_text": from_verse_data.get("text", ""),
				"scripture_location": "%s %s:%s" % [cross_reference["from_book"], str(cross_reference["from_chapter"]), str(cross_reference["from_verse"])],
				"translation": from_verse_data.get("translation_abbr", ""),
				"book": cross_reference["from_book"],
				"chapter": cross_reference["from_chapter"],
				"verse": cross_reference["from_verse"],
				"verse_hash": from_verse_hash
			})
			node_ids[from_node_id] = true

		if not node_ids.has(to_node_id):
			nodes.append({
				"id": to_node_id,
				"scripture_text": to_verse_data.get("text", ""),
				"scripture_location": "%s %s:%s" % [cross_reference["to_book"], str(cross_reference["to_chapter_start"]), str(cross_reference["to_verse_start"])],
				"translation": to_verse_data.get("translation_abbr", ""),
				"book": cross_reference["to_book"],
				"chapter": cross_reference["to_chapter_start"],
				"verse": cross_reference["to_verse_start"],
				"verse_hash": to_verse_hash
			})
			node_ids[to_node_id] = true

		edges.append({
			"id": edge_id,
			"source": from_node_id,
			"target": to_node_id,
			"weight": cross_reference["votes"]
		})
		edge_id += 1
	export_data["nodes"] = nodes	
	export_data["connections"] = edges

func get_verse_data(translation:String, book:String, chapter:int, verse:int) -> Dictionary:
	return ScriptureService.get_verse_from_version_dictionary(version_dict, translation, book, chapter, verse)

func export() -> void:
	# Generate GEXF data using GephiNetwork
	var gexf_data:String = gephi_network.generate_gexf().strip_edges()

	# Save to File 
	save_to_file(gexf_data)

func save_to_file(content):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		Command.print_to_console("Could not write export: %s" % save_path)
		return
	file.store_string(content)
