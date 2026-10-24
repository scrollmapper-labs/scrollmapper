extends Control
class_name LaunchSplash

signal dismissed

@export var credits_grid:GridContainer
@export var compact_breakpoint:float = 760.0

var _dismiss_pending:bool = false

func _ready() -> void:
	resized.connect(_update_layout)
	_update_layout()

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		dismiss()

func _gui_input(event:InputEvent) -> void:
	# Credit buttons stop their own mouse events before they reach this background.
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		accept_event()
		dismiss()

func dismiss() -> void:
	if _dismiss_pending:
		return
	_dismiss_pending = true
	dismissed.emit()
	_show_menu.call_deferred()

func _update_layout() -> void:
	credits_grid.columns = 2 if size.x < compact_breakpoint else 4

func _show_menu() -> void:
	UserInput.force_release_drag()
	GameManager.load_level("HOME")
