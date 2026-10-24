extends MarginContainer

class_name ReadingScripture

var verse_id: int = -1
var verse_hash: int = -1
var book_id: int = -1
var chapter: int = -1
var verse: int = -1:
	set(value):
		verse = value
		set_verse_number(value)		
var text: String = "":
	set(value):
		text = value
		set_verse_text(value)		
var book_name: String = ""
var translation_id: int = -1
var translation_abbr: String = ""
var title: String = ""
var license: String = ""

@export var interaction_button: Button
@export var verse_number_text_rich_text_label: RichTextLabel 
@export var text_rich_text_label: RichTextLabel

var is_cross_reference_scripture:bool = false:
	set(value):
		is_cross_reference_scripture = value
		if value:
			convert_to_cross_reference()

signal scripture_pressed(translation_abbr:String, book_name:String, chapter:int, verse:int)

func _ready() -> void:
	interaction_button.pressed.connect(_on_scripture_pressed)
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.55, 0.49, 0.33, 0.09)
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	interaction_button.add_theme_stylebox_override("hover", hover)
	interaction_button.add_theme_stylebox_override("pressed", hover)

func set_verse_number(verse_number:int) -> void:
	verse_number_text_rich_text_label.text = str(verse_number)

func set_verse_text(text:String) -> void:
	text_rich_text_label.text = text

func convert_to_cross_reference() -> void:
	verse_number_text_rich_text_label.hide()
	var scripture_location:String = " - %s %s:%s [%s]"%[
		book_name, str(chapter), str(verse), translation_abbr
	]
	text_rich_text_label.text = text_rich_text_label.text + scripture_location

func _on_scripture_pressed() -> void:
	scripture_pressed.emit(translation_abbr, book_name, chapter, verse)


func set_highlighted(highlighted:bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.55, 0.49, 0.33, 0.13 if highlighted else 0.0)
	style.border_width_left = 2 if highlighted else 0
	style.border_color = Color("ad9061")
	interaction_button.add_theme_stylebox_override("normal", style)
	interaction_button.flat = not highlighted
