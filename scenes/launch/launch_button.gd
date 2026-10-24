@tool
extends Button
class_name LaunchButton

## Destinations are configured on each button in the Inspector.
@export var destination_level:String = ""
@export var destination_url:String = ""

func _ready() -> void:
	if not Engine.is_editor_hint():
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if not destination_url.is_empty():
		OS.shell_open(destination_url)
	elif not destination_level.is_empty():
		# Wait until this input event finishes before replacing the active screen.
		GameManager.load_level.call_deferred(destination_level)
