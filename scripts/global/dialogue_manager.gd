extends Node

const BASE_DIALOGUE = preload("res://scenes/modules/dialogues/base_dialogue.tscn")

const FILE_SAVE_DIALOG = preload("res://scenes/modules/dialogues/file_save_dialog.tscn")

const FILE_LOAD_DIALOG = preload("res://scenes/modules/dialogues/file_load_dialog.tscn")

const PROGRESS_DIALOGUE = preload("res://scenes/modules/dialogues/export_cross_references_from_vx/progress_dialogue.tscn")

var file_save_dialog:FileDialog = null
var file_load_dialog:FileDialog = null
var progress_viewing_dialogue:ProgressDialogue = null
var main_progress_dialogue_container:BaseDialogue = null

## Signal: file_selected is the file that was selected during last file select dialogue.
signal file_selected(file_path:String)

func _ready() -> void:
	# Set up the file save dialogue.
	file_save_dialog = FILE_SAVE_DIALOG.instantiate()
	file_save_dialog.file_selected.connect(_on_file_selected)
	file_save_dialog.visible = false
	add_child(file_save_dialog)
	hide_file_save_dialog()
	# Set up the file load dialogue.
	file_load_dialog = FILE_LOAD_DIALOG.instantiate()
	file_load_dialog.file_selected.connect(_on_file_selected)
	file_load_dialog.visible = false
	add_child(file_load_dialog)
	hide_file_load_dialog()
	create_progress_dialogue()

func create_progress_dialogue():
	progress_viewing_dialogue = PROGRESS_DIALOGUE.instantiate()
	main_progress_dialogue_container = create_dialogue(progress_viewing_dialogue, self)
	hide_progress_dialog()

func set_progress_dialogue_text(text:String) -> void:
	progress_viewing_dialogue.set_status_text(text)

func set_progress_dialogue_values(current_amount:int, max_amount:int) -> void:
	progress_viewing_dialogue.total_amount = max_amount
	progress_viewing_dialogue.current_amount = current_amount

## Will show the file save dialogue.
func show_file_save_dialog(filters:PackedStringArray = ["*.gexf"]) -> FileDialog:
	file_save_dialog.set_filters(filters)
	file_save_dialog.show()
	return file_save_dialog

## Will hide the file save dialogue.
func hide_file_save_dialog() -> void:
	file_save_dialog.hide()
	

## Will show the file load dialogue.
func show_file_load_dialog() -> FileDialog:
	file_load_dialog.show()
	return file_load_dialog

## Will hide the file load dialogue.
func hide_file_load_dialog() -> void:
	file_load_dialog.hide()

func show_progress_dialog() -> void:
	main_progress_dialogue_container.open()
	
func hide_progress_dialog() -> void:
	main_progress_dialogue_container.close()

## Sets progress dialog to a given parent. Reparents to self if parent not supplied. 
## Created for the situation when progress dialog is shown via this class, and 
## must be shown in front of other elements.
func reparent_progress_dialog(parent = null) -> void:
	if parent == null:
		parent = self
	main_progress_dialogue_container.reparent(parent)

func _on_file_selected(selected_file:String) -> void:
	file_selected.emit(selected_file)
	hide_file_save_dialog()


## Function: create_dialogue
## Description: Creates a dialogue and adds it to the specified anchor node.
## This is a generic function that can be used to create any dialogue.
## 
## Parameters:
## - content (Control): The content of the dialogue. This must be a Control node.
## - anchor_to (Node): The node to which the content will be added as a child.
## 
## Usage:
## Call this function with the dialogue content and the node you want to anchor it to.
## Example:
## create_dialogue(dialogue_content, anchor_node)
func create_dialogue(content:Control, anchor_to:Node) -> Control:
	var bd:BaseDialogue = BASE_DIALOGUE.instantiate()
	bd.set_content(content)
	content.base_dialogue = bd
	anchor_to.add_child(bd)
	return bd
