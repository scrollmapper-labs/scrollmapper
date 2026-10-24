extends Node

var failures:int = 0
var checks:int = 0

func check(condition:bool, message:String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)
	else:
		print("PASS: ", message)

func frames(count:int = 3) -> void:
	for i in count:
		await get_tree().process_frame

func _ready() -> void:
	# This suite must never write to the regular application profile.
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		print("Run with XDG_DATA_HOME pointing to a fresh directory under /tmp.")
		get_tree().quit(2)
		return
	if DisplayServer.get_name() == "headless":
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1280, 900)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_size = Vector2i(1280, 900)
	await frames()
	check(ScriptureService.get_verse("KJV", "Genesis", 1, 1).size() == 1, "First-run bundled database")
	check(LibraryManager.source_reference_list.get_all_sources().size() > 0, "First-run source list")
	if "--capture-launch" in OS.get_cmdline_user_args():
		await capture_launch()
		return
	await test_launch()
	if "--capture-reader" in OS.get_cmdline_user_args():
		await capture_reader()
		return
	await test_reader()
	await test_modules()
	await test_installation()
	await test_graphs()
	test_scripture()
	test_exports()
	await test_downloads()
	print("REGRESSION RESULT: %s checks, %s failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func test_modules() -> void:
	for level in ["READER", "EXPLORER", "BOOK_LIBRARY", "META_EDITOR", "HOME", "invalid_level"]:
		GameManager.load_level(level)
		await frames()
		check(is_instance_valid(GameManager.current_level), "Open module: " + level)
	GameManager.load_level("EXPLORER")
	await frames()
	var search:Search = find_search(GameManager.current_level)
	check(search != null, "Explorer search is available")
	if search:
		search.set_scope(2)
		check(search.option_scope.selected == 2, "Search scope stays selected")
		check(search.option_books.item_count > 1, "Scope change refreshes book choices")
	GameManager.load_level("HOME")
	await frames()

func find_search(node:Node) -> Search:
	if node is Search:
		return node
	for child in node.get_children():
		var found = find_search(child)
		if found:
			return found
	return null

func test_installation() -> void:
	var data_manager = DataManager.new()
	var verses:Array = []
	for number in range(1, 106):
		verses.append({"chapter": 1, "verse": number, "text": "Audit verse %s" % number})
	var data = {"books": [{"name": "Audit Book", "chapters": [{"verses": verses}]}]}
	var path = data_manager.get_book_path("audit_fixture")
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var installer = InstallBook.new("audit_fixture")
	installer.source_reference = SourceReference.new("en", "audit_fixture", "Audit Book", "", "bible")
	installer.translation = "audit_fixture"
	check(await installer.install(), "Install book spanning a bulk batch")
	check(ScriptureService.get_verses("audit_fixture", "Audit Book").size() == 105, "All installed verses are readable")
	data["books"][0]["chapters"][0]["verses"][0]["text"] = "Updated verse"
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	check(await installer.install(), "Reinstall an existing book")
	var installed = ScriptureService.get_verse("audit_fixture", "Audit Book", 1, 1)
	check(installed.size() == 1 and installed[0]["text"] == "Updated verse", "Reinstall updates existing verse IDs")
	check(installer.completed_iterations == 105 and installer.total_iterations == 105, "Reinstall resets progress counters")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{}")
	file.close()
	check(not await installer.install(), "Reject malformed book before installation")
	check(ScriptureService.get_verses("audit_fixture", "Audit Book").size() == 105, "Malformed replacement preserves installed verses")
	installer.free()

func test_graphs() -> void:
	var graph_data = VXService.create_new_empty_graph()
	check(VXService.get_saved_graph(graph_data["id"])["graph_name"] == "New Graph", "New graph name is persisted")
	check(VXService.get_or_create_graph(graph_data["id"])["id"] == graph_data["id"], "Get existing graph")
	check(VXService.get_or_create_graph(99999999)["id"] == -1, "Missing graph ID is handled")
	check(VXService.get_last_used_graph().is_empty(), "Missing last-used metadata is handled")
	GameManager.load_level("VX_GRAPH")
	await frames(10)
	var graph:VXGraph = VXGraph.instance
	check(is_instance_valid(graph), "Open graph editor")
	var verse_set = ScriptureService.get_verses("KJV", "Genesis", 1)
	var results = verse_set.slice(0, 2)
	for result in results:
		result["meta"] = {"work_space": "vx"}
	await graph._on_verses_searched(results)
	await frames(5)
	check(graph.vx_nodes.size() == 2, "Add every search result without connection metadata")
	var nodes = graph.vx_nodes.values()
	if nodes.size() != 2:
		return
	nodes[0].position = Vector2(123, 456)
	nodes[1].position = Vector2(789, 234)
	graph.connect_node_sockets(nodes[0].get_empty_socket(Types.SocketType.OUTPUT, Types.SocketDirectionType.LINEAR), nodes[1].get_empty_socket(Types.SocketType.INPUT, Types.SocketDirectionType.LINEAR))
	await frames(5)
	check(graph.vx_connections.size() == 1, "Create graph connection")
	if graph.vx_connections.is_empty():
		return
	graph.vx_connections.values()[0].text = "A saved connection note"
	var original = graph.get_full_graph_as_dictionary()
	var json_path = DataManager.new().get_scrollmapper_user_dir().path_join("roundtrip.json")
	var json_exporter = ExporterVXGraphToJson.new(graph, json_path)
	json_exporter.export()
	check(JSON.parse_string(FileAccess.get_file_as_string(json_path))["nodes"].size() == 2, "JSON export writes a readable graph file")
	json_exporter.free()
	VXService.save_graph(original)
	var restored = VXService.get_saved_graph(graph.id)
	await graph.set_full_graph_from_dictionary(restored)
	await frames(6)
	check(graph.vx_nodes.size() == 2 and graph.vx_connections.size() == 1, "Saved graph restores nodes and connections")
	check(graph.vx_nodes.values()[0].position == Vector2(123, 456), "Graph node position survives reload")
	check(graph.vx_connections.values()[0].text == "A saved connection note", "Connection note survives reload")
	var prepared = VXService.get_saved_graph_from_json(JSON.stringify(original))
	await graph.set_full_graph_from_dictionary(prepared)
	await frames(6)
	check(graph.vx_nodes.size() == 2 and graph.vx_connections.size() == 1, "JSON round trip restores graph structure")
	var invalid = original.duplicate(true)
	invalid["nodes"] = [{}]
	VXService.save_graph(invalid)
	check(VXService.get_saved_graph(original["id"])["nodes"].size() == 2, "Invalid save preserves existing graph relationships")
	await graph.set_full_graph_from_dictionary({})
	check(graph.vx_nodes.size() == 2, "Invalid import leaves current graph intact")
	var unsaved = original.duplicate(true)
	unsaved["id"] = -1
	VXService.save_graph(unsaved)
	check(unsaved["id"] > 0 and VXService.get_saved_graph(unsaved["id"])["nodes"].size() == 2, "New graph save uses its actual database ID")
	graph.set_selected_node(graph.vx_nodes.values()[0])
	graph.selected_nodes.append(graph.vx_nodes.values()[0])
	graph.clear_graph()
	await frames(5)
	check(graph.selected_node == null and graph.selected_nodes.is_empty(), "Clearing graph releases selections")
	GameManager.load_level("HOME")
	await frames()

func test_exports() -> void:
	var save_dialog = DialogueManager.show_file_save_dialog(PackedStringArray(["*.json"]))
	check(save_dialog.filters == PackedStringArray(["*.json"]), "Save dialog uses requested file filter")
	DialogueManager.hide_file_save_dialog()
	var network = GephiNetwork.new("2026-10-24", "A & B", "A < B", [{"id": 1, "verse_hash": 1, "book": "A & B", "scripture_text": 'He said "hello" & <goodbye>'}], [])
	network.add_verse_meta({"verse_hash": 1, "key": "one", "value": 'A & "B"'})
	network.add_verse_meta({"verse_hash": 1, "key": "two", "value": "C"})
	check(network.verse_meta[1].size() == 2, "Gephi export keeps multiple metadata fields per verse")
	var xml = network.generate_gexf()
	check(xml.contains("A &amp; B") and xml.contains("&quot;hello&quot; &amp; &lt;goodbye&gt;"), "Gephi XML escapes scripture and metadata")
	var parser = XMLParser.new()
	check(parser.open_buffer(xml.to_utf8_buffer()) == OK, "Gephi XML can be opened")
	var parse_error = parser.read()
	while parse_error == OK:
		parse_error = parser.read()
	check(parse_error == ERR_FILE_EOF, "Gephi XML parses completely")
	network.free()

func test_downloads() -> void:
	var downloader = ResourceDownloader.instance
	var path = DataManager.new().get_source_list_path()
	var previous = FileAccess.get_file_as_string(path)
	downloader.file_name = "book_list.json"
	downloader.is_processing_request = true
	downloader._http_request_completed(HTTPRequest.RESULT_SUCCESS, 404, [], "missing".to_utf8_buffer())
	check(not downloader.is_processing_request and not downloader.last_download_succeeded, "HTTP failure ends download state")
	check(FileAccess.get_file_as_string(path) == previous, "Failed download preserves cached source list")
	downloader.is_processing_request = true
	downloader._http_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], previous.to_utf8_buffer())
	check(downloader.last_download_succeeded and FileAccess.get_file_as_string(path) == previous, "Successful download replaces the cache with validated JSON")
	downloader.is_processing_request = true
	downloader.file_name = "unchanged.json"
	check(not downloader.retrieve_source_list() and downloader.file_name == "unchanged.json", "Concurrent download cannot change the active filename")
	downloader.is_processing_request = false
	downloader.file_name = "book_list.json"
	downloader.is_processing_request = true
	downloader._http_request_completed(HTTPRequest.RESULT_SUCCESS, 200, [], "{}".to_utf8_buffer())
	check(not downloader.last_download_succeeded and FileAccess.get_file_as_string(path) == previous, "Invalid JSON shape preserves cached source list")
	check(downloader.download_file("invalid://url", Types.DataDir.SOURCES), "Request startup reports accepted operation")
	await downloader.download_process_complete
	check(not downloader.is_processing_request and not downloader.last_download_succeeded, "Immediate request failure completes without hanging")


func test_reader() -> void:
	var shared_theme:Theme = load("res://theme/scrollmapper_theme.tres")
	var font:Font = shared_theme.default_font if shared_theme.default_font else ThemeDB.fallback_font
	var original_fixed_size = font.fixed_size
	var fallback_size = ThemeDB.fallback_font.fixed_size
	GameManager.load_level("READER")
	await frames(5)
	var reader:Reader = GameManager.current_level
	check(reader.reading_v_box_container.get_child_count() > 2, "Reader opens with a passage")
	check(reader.previous_chapter_button.disabled, "Previous chapter is disabled at the start")
	check(reader.reading_scroll_container.get_v_scroll_bar().max_value > reader.reading_scroll_container.get_v_scroll_bar().page, "Long chapters scroll within the reading pane")
	reader.font_size_spin_box.value = 30
	await frames()
	var row:ReadingScripture = null
	for child in reader.reading_v_box_container.get_children():
		if child is ReadingScripture and not child.is_queued_for_deletion():
			row = child
			break
	check(row != null and row.text_rich_text_label.get_theme_font_size("normal_font_size") == 30, "Font control resizes reader text")
	check(font.fixed_size == original_fixed_size and ThemeDB.fallback_font.fixed_size == fallback_size, "Reader font setting leaves shared and fallback fonts unchanged")
	reader._on_spacing_changed(2)
	check(row.text_rich_text_label.get_theme_constant("line_separation") == 14, "Line spacing applies to reader text")
	reader.next_chapter()
	await frames()
	check(reader.current_chapter == 2 and not reader.previous_chapter_button.disabled, "Chapter navigation updates state and controls")
	reader.show_cross_referencing_browser()
	reader.distraction_free_button.set_pressed(true)
	check(not reader.browser_margin_container.visible and not reader.cross_referencing_margin_container.visible, "Focus mode hides side panels")
	reader.distraction_free_button.set_pressed(false)
	check(reader.cross_referencing_margin_container.visible and reader.browser_margin_container.visible == (reader.size.x >= 1100), "Leaving focus restores responsive side panels")
	ScriptureService.request_cross_references("KJV", "not_a_book", 1, 1)
	check(reader.references_hint.text.contains("No cross-references"), "Empty cross-references have an explanatory state")
	GameManager.load_level("HOME")
	await frames()
	check(font.fixed_size == original_fixed_size and ThemeDB.fallback_font.fixed_size == fallback_size, "Leaving reader preserves app typography")
	GameManager.load_level("READER")
	await frames(5)
	reader = GameManager.current_level
	check(reader.get_font_size() == 30 and reader.reader_line_spacing == 14, "Reader restores its own typography preferences")
	check(reader.current_chapter == 2, "Reader restores the last passage")
	reader.show_chapter("KJV", "Genesis", 1)
	reader.font_size_spin_box.value = 20
	reader._on_spacing_changed(1)
	GameManager.load_level("HOME")
	await frames()

func capture_reader() -> void:
	GameManager.load_level("READER")
	await frames(8)
	var reader:Reader = GameManager.current_level
	reader.show_chapter("KJV", "Genesis", 1)
	await frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-reader.png")
	reader.request_cross_references("KJV", "Genesis", 1, 1)
	await frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-reader-references.png")
	reader.distraction_free_button.set_pressed(true)
	await frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-reader-focus.png")
	get_tree().quit()


func test_scripture() -> void:
	var model = VerseModel.new("KJV")
	var source = ScriptureService.get_verses("KJV", "Genesis", 1).slice(0, 2)
	var ordered = model.get_verses_by_ids([source[1]["verse_id"], source[0]["verse_id"]])
	check(ordered.size() == 2 and ordered[0]["verse"] == 2 and ordered[1]["verse"] == 1, "ID search preserves requested ordering")
	ordered = model.get_verses_by_verse_hashes([source[1]["verse_hash"], source[0]["verse_hash"]])
	check(ordered.size() == 2 and ordered[0]["verse"] == 2, "Hash search preserves requested ordering")
	ScriptureService.save_cross_reference("Audit Source", 1, 1, "Genesis", 1, 2, 30, 2, 1, true)
	var references = ScriptureService.get_cross_references_for_verse("KJV", "Audit Source", 1, 1)
	check(references.size() == 4, "Cross-reference range spans chapter boundaries")
	check(references.any(func(verse): return verse["chapter"] == 2 and verse["verse"] == 1), "Cross-reference range includes start of next chapter")
	ScriptureService.set_verse_meta(1, "audit", "value")
	check(ScriptureService.get_verse_meta(1, "audit").get("value") == "value", "Verse metadata saves and loads")


func pointer_click(position:Vector2, button:MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var motion = InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_viewport().push_input(motion, true)
	await frames()
	for pressed in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = position
		event.global_position = position
		event.button_index = button
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await frames()

func test_launch() -> void:
	var splash = GameManager.current_level as LaunchSplash
	check(splash != null, "Application starts at the splash screen")
	if splash == null:
		return
	check(get_tree().get_nodes_in_group("launchers").is_empty(), "Startup uses the new 2D screen")
	check(splash.credits_grid.get_child_count() == 4, "Splash has four project credit cards")
	var credit = splash.credits_grid.get_child(1) as LaunchButton
	check(credit.destination_url == "https://github.com/scrollmapper/bible_databases", "Splash credit points to the requested repository")
	# Test real GUI event routing without opening an external browser.
	credit.pressed.disconnect(credit._on_pressed)
	var clicks = [0]
	credit.pressed.connect(func(): clicks[0] += 1)
	await pointer_click(credit.get_global_rect().get_center())
	check(clicks[0] == 1 and GameManager.current_level == splash, "Credit click activates its link without dismissing the splash")
	await pointer_click(Vector2(12, 12))
	check(GameManager.current_level is LaunchMenu, "Clicking the splash background opens the main menu")
	GameManager.load_level("SPLASH")
	await frames()
	var key = InputEventKey.new()
	key.keycode = KEY_F10
	key.pressed = true
	Input.parse_input_event(key)
	await frames()
	check(GameManager.current_level is LaunchMenu, "Any key dismisses the splash")
	check(not UserInput.is_dragging, "Dismissing the splash does not leave input dragging")
	var menu:LaunchMenu = GameManager.current_level
	check(menu.projects_grid.get_child_count() == 4, "Menu includes all repository and documentation cards")
	for grid in [menu.feature_grid, menu.tools_grid]:
		for card in grid.get_children():
			check(not card.destination_level.is_empty(), "Menu card has a feature destination: " + card.title)
	var destinations = {
		"FeatureGrid/Mapping": "VX_GRAPH",
		"FeatureGrid/Explorer": "EXPLORER",
		"ToolsGrid/Reader": "READER",
		"ToolsGrid/Library": "BOOK_LIBRARY",
		"ToolsGrid/Metadata": "META_EDITOR",
	}
	for path in destinations:
		menu = GameManager.current_level
		var card:LaunchButton = menu.get_node("Scroll/ContentMargin/Layout/" + path)
		check(card.destination_level == destinations[path], "Menu destination is correct: " + destinations[path])
		menu.get_node("Scroll").ensure_control_visible(card)
		await frames()
		await pointer_click(card.get_global_rect().get_center())
		await frames(10)
		check(not GameManager.current_level is LaunchMenu and not GameManager.current_level is LaunchSplash, "Menu opens feature: " + destinations[path])
		GameManager.load_level("HOME")
		await frames(5)
		check(GameManager.current_level is LaunchMenu, "Returning Home opens the menu without replaying the splash")
	menu = GameManager.current_level
	var reader_card:LaunchButton = menu.get_node("Scroll/ContentMargin/Layout/ToolsGrid/Reader")
	reader_card.grab_focus()
	await frames()
	for pressed in [true, false]:
		var accept = InputEventKey.new()
		accept.keycode = KEY_ENTER
		accept.physical_keycode = KEY_ENTER
		accept.pressed = pressed
		get_viewport().push_input(accept, true)
		await frames()
	check(GameManager.current_level is Reader, "Menu supports keyboard activation of workspace cards")
	GameManager.load_level("HOME")
	await frames()
	menu = GameManager.current_level
	menu.size.x = 580
	menu._update_layout()
	await frames()
	check(menu.feature_grid.columns == 1 and menu.tools_grid.columns == 1 and menu.projects_grid.columns == 1, "Menu cards reflow at compact widths")
	check(menu.get_node("Scroll").get_h_scroll_bar().max_value <= menu.get_node("Scroll").get_h_scroll_bar().page, "Compact menu avoids horizontal overflow")
	menu.size = get_viewport().get_visible_rect().size
	menu._update_layout()
	await frames()

func capture_launch() -> void:
	var window = get_window()
	window.mode = Window.MODE_WINDOWED
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_size = Vector2i(1440, 1000)
	window.size = Vector2i(1440, 1000)
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-splash.png")
	GameManager.current_level.dismiss()
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-menu.png")
	window.content_scale_size = Vector2i(960, 700)
	window.size = Vector2i(960, 700)
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-menu-small.png")
	var menu:LaunchMenu = GameManager.current_level
	menu.get_node("Scroll").scroll_vertical = 10000
	await frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-menu-resources.png")
	window.content_scale_size = Vector2i(580, 800)
	window.size = Vector2i(580, 800)
	await frames(12)
	menu.get_node("Scroll").scroll_vertical = 0
	await frames(5)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-menu-compact.png")
	GameManager.load_level("SPLASH")
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/scrollmapper-splash-compact.png")
	get_tree().quit()
