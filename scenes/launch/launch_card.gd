@tool
extends LaunchButton
class_name LaunchCard

## Reusable scene-backed card; content and destinations stay editable in the Inspector.
@export var title:String = "Workspace":
	set(value):
		title = value
		_update_label("Title", value)
@export_multiline var description:String = "":
	set(value):
		description = value
		_update_label("Description", value)
@export var category:String = "":
	set(value):
		category = value
		_update_label("Category", value)
@export var action_text:String = "Open workspace  →":
	set(value):
		action_text = value
		_update_label("Action", value)
@export var artwork:Texture2D:
	set(value):
		artwork = value
		var image = get_node_or_null("Artwork") as TextureRect
		if image:
			image.texture = value

func _ready() -> void:
	super._ready()
	_update_label("Title", title)
	_update_label("Description", description)
	_update_label("Category", category)
	_update_label("Action", action_text)
	$Artwork.texture = artwork

func _update_label(node_name:String, value:String) -> void:
	var label = get_node_or_null("Margin/Content/" + node_name) as Label
	if label:
		label.text = value
