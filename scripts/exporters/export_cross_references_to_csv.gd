extends BaseExporter

class_name ExporterCrossReferencesToCSV

var save_path: String = ""
var books: Array = []
var format:String = ""
var csv:String = ""
var user_added:bool = false

func _init(_save_path: String, _books: Array[String] = [], _format="Scrollmapper", _user_added=false) -> void:
	save_path = _save_path
	books = _books
	format = _format
	user_added = _user_added
	populate_export_data()

func populate_export_data():
	var cross_reference_model:CrossReferenceModel = CrossReferenceModel.new("scrollmapper")
	var cross_references:Array = cross_reference_model.get_cross_references_by_books(books, user_added)
	match format:
		"Scrollmapper":
			var csv_scrollmapper:CSVFormatScrollmapper = CSVFormatScrollmapper.new(cross_references)	
			csv = csv_scrollmapper.get_csv()
		"OpenBible":
			var csv_openbible:CSVFormatOpenBible = CSVFormatOpenBible.new(cross_references)
			csv = csv_openbible.get_csv()

func export() -> void:
	save_to_file(csv)

func save_to_file(content: String):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		Command.print_to_console("Could not write export: %s" % save_path)
		return
	file.store_string(content)
