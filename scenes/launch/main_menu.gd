extends Control
class_name LaunchMenu

@export_group("Scene Connections")
@export var feature_grid:GridContainer
@export var tools_grid:GridContainer
@export var projects_grid:GridContainer
@export var content_margin:MarginContainer
@export var version_label:Label

@export_group("Responsive Layout")
@export var content_max_width:float = 1400.0
@export var wide_breakpoint:float = 980.0
@export var compact_breakpoint:float = 620.0
@export var workspace_breakpoint:float = 820.0
@export var edge_padding:int = 32

func _ready() -> void:
	version_label.text = "VERSION " + str(ProjectSettings.get_setting("application/config/version", ""))
	resized.connect(_update_layout)
	_update_layout()

func _update_layout() -> void:
	# Reflow existing editor-designed nodes; no controls are created at runtime.
	feature_grid.columns = 1 if size.x < workspace_breakpoint else 2
	tools_grid.columns = 1 if size.x < workspace_breakpoint else 3
	projects_grid.columns = 2 if size.x < wide_breakpoint else 4
	if size.x < compact_breakpoint:
		projects_grid.columns = 1
	var padding:int = int(maxf(edge_padding, (size.x - content_max_width) / 2.0))
	content_margin.add_theme_constant_override("margin_left", padding)
	content_margin.add_theme_constant_override("margin_right", padding)
