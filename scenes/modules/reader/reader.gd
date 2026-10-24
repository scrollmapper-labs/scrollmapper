extends Control

class_name Reader

const READING_SCRIPTURE = preload("res://scenes/modules/reader/reading_scripture/reading_scripture.tscn")
const READING_TITLE = preload("res://scenes/modules/reader/reading_title/reading_title.tscn")
const READER_CHAPTER_BUTTON = preload("res://scenes/modules/reader/reader_chapter_button/reader_chapter_button.tscn")

@export var books_button: Button 
@export var previous_chapter_button: Button 
@export var cross_refs_button: Button 
@export var next_chapter_button: Button 

@export var browser_margin_container: MarginContainer 
@export var chapters_v_box_container: VBoxContainer 
@export var reading_v_box_container: VBoxContainer 
@export var cross_referencing_margin_container: MarginContainer
@export var cross_referencing_v_box_container: VBoxContainer
@export var reader_book_selector: ReaderBooksSelector

@export var chapers_scroll_container: ScrollContainer 
@export var reading_scroll_container: ScrollContainer 
@export var cross_referencing_scroll_container: ScrollContainer 

@export var distraction_free_button: Button 
@export var font_size_spin_box: SpinBox 

var original_font_size:float = 20
var reader_font_size:float = 20
var reader_line_spacing:int = 8
var references_before_focus:bool = false
var selected_verse:ReadingScripture = null

@onready var spacing_option:OptionButton = $Layout/Footer/Settings/Spacing
@onready var status_label:Label = $Layout/Footer/Status
@onready var references_hint:Label = $Layout/Body/References/ReferenceLayout/Hint
@onready var article_margin:MarginContainer = $Layout/Body/ReadingPanel/ReadingScrollContainer/ArticleMargin

var current_translation:String = "KJV"
var current_book:String = "Genesis"
var current_chapter:int = 1

var minimum_chapter:int = 1
var maximum_chapter:int = 1

func _ready() -> void:
	ScriptureService.verse_cross_references_searched.connect(_on_cross_references_received)
	books_button.pressed.connect(show_reader_book_selector)
	reader_book_selector.book_chosen.connect(_on_book_chosen)
	cross_refs_button.pressed.connect(toggle_cross_references)
	previous_chapter_button.pressed.connect(previous_chapter)
	next_chapter_button.pressed.connect(next_chapter)	
	distraction_free_button.toggled.connect(_on_distraction_free_button_toggled)
	font_size_spin_box.value_changed.connect(_on_font_size_spin_box_changed)
	original_font_size = get_font_size()
	var settings = MetaService.get_meta_data("reader_settings")
	reader_font_size = clampf(float(settings.get("font_size", 20)), 14, 36)
	reader_line_spacing = int(settings.get("line_spacing", 8))
	if reader_line_spacing not in [2, 8, 14]:
		reader_line_spacing = 8
	font_size_spin_box.set_value_no_signal(reader_font_size)
	for label in ["Compact spacing", "Comfortable spacing", "Spacious spacing"]:
		spacing_option.add_item(label)
	spacing_option.select([2, 8, 14].find(reader_line_spacing))
	spacing_option.item_selected.connect(_on_spacing_changed)
	$Layout/Footer/Home.pressed.connect(func(): GameManager.load_level("HOME"))
	reading_scroll_container.resized.connect(_update_reading_width)
	resized.connect(_update_responsive_layout)
	hide_reader_book_selector()
	open_saved_passage()
	hide_cross_referencing_browser()
	distraction_free_button.set_pressed(bool(settings.get("focus_mode", false)))
	_update_reading_width.call_deferred()

func _exit_tree() -> void:
	# Font size should be reset to original size on exit. 
	set_font_size(original_font_size)

## Show the chapter for the given translation, book, and chapter
## The main chapter display function. Use it for the reader from any 
## other chapter-display need.
func show_chapter(translation_abbr:String, book:String, chapter:int = 1) -> void:
	current_translation = translation_abbr
	current_book = book
	current_chapter = chapter
	var verses:Array = ScriptureService.get_verses(translation_abbr, book, chapter)
	selected_verse = null
	clear_reading_browser()
	clear_cross_referencing_browser()
	references_hint.text = "Select a verse in the reading pane."
	populate_chapter_buttons()
	var chapter_heading:ReadingTitle = create_reading_title("%s %s" % [book, chapter])
	var edition = Label.new()
	edition.text = "%s  /  CHAPTER %s" % [translation_abbr.to_upper(), chapter]
	edition.add_theme_font_size_override("font_size", 12)
	edition.add_theme_color_override("font_color", Color("887654"))
	reading_v_box_container.add_child(edition)
	reading_v_box_container.add_child(chapter_heading)
	for verse:Dictionary in verses:
		var reading_scripture:ReadingScripture = create_reading_scripture(verse)
		reading_v_box_container.add_child(reading_scripture)
	reading_scroll_container.scroll_vertical = 0
	previous_chapter_button.disabled = current_chapter <= minimum_chapter or verses.is_empty()
	next_chapter_button.disabled = current_chapter >= maximum_chapter or verses.is_empty()
	books_button.text = "%s · %s" % [book, translation_abbr]
	status_label.text = "%s %s  ·  %s verses" % [book, chapter, verses.size()]
	if verses.is_empty():
		var empty = create_reading_title("This passage is unavailable. Choose an installed book to begin reading.")
		empty.title_rich_text_label.add_theme_font_size_override("normal_font_size", 20)
		reading_v_box_container.add_child(empty)
	else:
		MetaService.set_meta_data("reader_position", {"translation": translation_abbr, "book": book, "chapter": chapter})

## Show the next chapter
func next_chapter() -> void:
	if current_chapter < maximum_chapter:
		current_chapter += 1
		show_chapter(current_translation, current_book, current_chapter)

## Show the previous chapter
func previous_chapter() -> void:
	if current_chapter > minimum_chapter:
		current_chapter -= 1
		show_chapter(current_translation, current_book, current_chapter)

## Populate the chapter buttons
func populate_chapter_buttons():
	clear_chapters_browser()
	var chapters:Dictionary = ScriptureService.get_all_chapter_numbers_in_book(current_translation, current_book )
	for chapter in chapters["chapters"]:
		var reader_chapter_button:ReaderChapterButton = create_reader_chapter_button(current_translation, current_book, chapter)
		chapters_v_box_container.add_child(reader_chapter_button)
	update_min_max_chapters_for_book(chapters["chapters"])
	chapers_scroll_container.scroll_vertical = 0

## Update the minimum and maximum chapters for the current book
func update_min_max_chapters_for_book(chapters:Array) -> void:
	minimum_chapter = 1 if chapters.is_empty() else int(chapters.min())
	maximum_chapter = 1
	for chapter in chapters:
		if chapter < minimum_chapter:
			minimum_chapter = chapter
		if chapter > maximum_chapter:
			maximum_chapter = chapter

## Request cross-references for the given translation, book, chapter, and verse
func request_cross_references(_translation:String, _book_name:String, _chapter:int, _verse:int) -> void:
	for child in reading_v_box_container.get_children():
		if child is ReadingScripture:
			child.set_highlighted(child.chapter == _chapter and child.verse == _verse)
	references_hint.text = "References for %s %s:%s" % [_book_name, _chapter, _verse]
	ScriptureService.request_cross_references(_translation, _book_name, _chapter, _verse)

func _on_cross_references_received(cross_references:Array) -> void:
	clear_cross_referencing_browser()
	if cross_references.is_empty():
		references_hint.text += "\n\nNo cross-references are available for this verse."
	for cross_reference in cross_references:
		var reading_scripture:ReadingScripture = create_reading_scripture(cross_reference)
		reading_scripture.convert_to_cross_reference()
		apply_scripture_style(reading_scripture, true)
		cross_referencing_v_box_container.add_child(reading_scripture)
	if distraction_free_button.button_pressed:
		distraction_free_button.set_pressed(false)
	show_cross_referencing_browser()
	cross_referencing_scroll_container.scroll_vertical = 0

## Toggle the cross-referencing container
func toggle_cross_references() -> void:
	var should_hide = cross_referencing_margin_container.visible
	if not should_hide and distraction_free_button.button_pressed:
		distraction_free_button.set_pressed(false)
	if should_hide:
		hide_cross_referencing_browser()
	else:
		show_cross_referencing_browser()

## Show the reader
func show_reader_book_selector() -> void:
	reader_book_selector.show()

## Hide the reader
func hide_reader_book_selector() -> void:
	reader_book_selector.hide()

## Clear the chapters browser
func clear_chapters_browser() -> void:
	for child in chapters_v_box_container.get_children():
		child.queue_free()

## Clear the reading browser
func clear_reading_browser() -> void:
	for child in reading_v_box_container.get_children():
		child.queue_free()

## Clear the cross-referencing browser
func clear_cross_referencing_browser() -> void:
	for child in cross_referencing_v_box_container.get_children():
		child.queue_free()

## Hide the cross-referencing browser
func hide_cross_referencing_browser():
	cross_referencing_margin_container.hide()
	cross_refs_button.set_pressed_no_signal(false)
	_update_responsive_layout()

## Show the cross-referencing browser
func show_cross_referencing_browser():
	cross_referencing_margin_container.show()
	cross_refs_button.set_pressed_no_signal(true)
	_update_responsive_layout()

func hide_chapters_browser() -> void:
	browser_margin_container.hide()
	
func show_chapters_browser() -> void:
	browser_margin_container.show()

## Create a reading scripture object
## This is the scripture for reading.
## It is for reading a scripture.
## More documentation here: https://www.youtube.com/watch?v=CLeJ-tZBqKY 
func create_reading_scripture(verse:Dictionary) -> ReadingScripture:
	var rs:ReadingScripture = READING_SCRIPTURE.instantiate()
	rs.translation_id = verse["translation_id"]
	rs.translation_abbr = verse["translation_abbr"]
	rs.book_id = verse["book_id"]
	rs.book_name = verse["book_name"]
	rs.chapter = verse["chapter"]
	rs.verse = verse["verse"]
	rs.verse_id = verse["verse_id"]
	#rs.verse_hash = verse["verse_hash"]
	rs.text = verse["text"]
	rs.title = verse["title"]
	rs.license = verse["license"]
	rs.scripture_pressed.connect(request_cross_references)
	apply_scripture_style(rs)
	return rs
	
func create_reading_title(title:String) -> ReadingTitle:
	var rt:ReadingTitle = READING_TITLE.instantiate()
	rt.title = title
	rt.add_theme_constant_override("margin_top", 8)
	rt.add_theme_constant_override("margin_bottom", 28)
	rt.title_rich_text_label.add_theme_color_override("default_color", Color("292d2d"))
	rt.title_rich_text_label.add_theme_font_size_override("normal_font_size", 36)
	return rt

func create_reader_chapter_button(translation:String, book:String, chapter:int) -> ReaderChapterButton:
	var rcb:ReaderChapterButton = READER_CHAPTER_BUTTON.instantiate()
	rcb.translation = translation
	rcb.book = book
	rcb.chapter = chapter
	rcb.toggle_mode = true
	rcb.button_pressed = chapter == current_chapter
	rcb.chapter_chosen.connect(show_chapter)
	return rcb
	
func _on_book_chosen(translation_abbr:String, book:String) -> void:
	show_chapter(translation_abbr, book, 1)

func _on_distraction_free_button_toggled(toggled:bool) -> void:
	if toggled:
		references_before_focus = cross_referencing_margin_container.visible
		hide_chapters_browser()
		hide_cross_referencing_browser()
	else:
		show_chapters_browser()
		if references_before_focus:
			show_cross_referencing_browser()
	_save_reader_settings()
		

func get_font_size() -> float:
	return reader_font_size


func set_font_size(value:float) -> void:
	reader_font_size = clampf(value, 14, 36)
	for child in reading_v_box_container.get_children():
		if child is ReadingScripture:
			apply_scripture_style(child)
	for child in cross_referencing_v_box_container.get_children():
		if child is ReadingScripture:
			apply_scripture_style(child, true)

func _on_font_size_spin_box_changed(value:float) -> void:
	set_font_size(value)
	_save_reader_settings()

func apply_scripture_style(scripture:ReadingScripture, reference:bool = false) -> void:
	# Override Control properties rather than mutating a shared Font or Theme resource.
	scripture.theme = theme
	var text_label = scripture.text_rich_text_label
	for key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		text_label.add_theme_font_size_override(key, int(reader_font_size))
	text_label.add_theme_constant_override("line_separation", reader_line_spacing)
	text_label.add_theme_color_override("default_color", Color("d5dde0") if reference else Color("353b3c"))
	scripture.verse_number_text_rich_text_label.add_theme_font_size_override("normal_font_size", 12)
	scripture.verse_number_text_rich_text_label.add_theme_color_override("default_color", Color("928063"))
	scripture.add_theme_constant_override("margin_bottom", reader_line_spacing + 4)
	scripture.interaction_button.tooltip_text = "Show cross-references for %s %s:%s" % [scripture.book_name, scripture.chapter, scripture.verse]

func _on_spacing_changed(index:int) -> void:
	reader_line_spacing = [2, 8, 14][index]
	set_font_size(reader_font_size)
	_save_reader_settings()

func _save_reader_settings() -> void:
	MetaService.set_meta_data("reader_settings", {"font_size": reader_font_size, "line_spacing": reader_line_spacing, "focus_mode": distraction_free_button.button_pressed})

func _update_reading_width() -> void:
	var width = reading_scroll_container.size.x
	var padding = int(maxf(24, (width - 760) / 2))
	article_margin.add_theme_constant_override("margin_left", padding)
	article_margin.add_theme_constant_override("margin_right", padding)

func open_saved_passage() -> void:
	var passage = MetaService.get_meta_data("reader_position")
	var translation:String = passage.get("translation", "KJV")
	var book:String = passage.get("book", "Genesis")
	var chapter:int = int(passage.get("chapter", 1))
	if ScriptureService.is_translation_installed(translation) and not ScriptureService.get_verses(translation, book, chapter).is_empty():
		show_chapter(translation, book, chapter)
		return
	for installed in ScriptureService.get_all_translations():
		var available = ScriptureService.get_all_books(installed["translation_abbr"])
		if not available.is_empty():
			var chapters = ScriptureService.get_all_chapter_numbers_in_book(installed["translation_abbr"], available[0]["book_name"])["chapters"]
			if not chapters.is_empty():
				show_chapter(installed["translation_abbr"], available[0]["book_name"], int(chapters[0]))
				return
	show_chapter(translation, book, chapter)

func _unhandled_key_input(event:InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or reader_book_selector.visible:
		return
	var focused = get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is SpinBox:
		return
	if event.keycode == KEY_LEFT:
		previous_chapter()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_RIGHT:
		next_chapter()
		get_viewport().set_input_as_handled()


func _update_responsive_layout() -> void:
	if not is_node_ready():
		return
	browser_margin_container.visible = not distraction_free_button.button_pressed and not (size.x < 1100 and cross_referencing_margin_container.visible)
	cross_referencing_margin_container.custom_minimum_size.x = clampf(size.x * 0.28, 260, 360)
