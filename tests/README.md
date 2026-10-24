Run the integration suite from the project root:

```sh
python tests/run_regression.py
```

The runner imports resources, starts the real application, and uses a fresh temporary profile under `/tmp`. Installed books, graphs, and preferences in the regular user profile are never used by the suite. Godot 4 and the included SQLite extension are required.

Checks cover first-run data, module navigation, reader typography isolation and persistence, responsive focus mode, chapter navigation and scrolling, installation and reinstallation, invalid replacement files, graph save/load and JSON round trips, search ordering, cross-reference ranges, verse metadata, GEXF escaping, file filters, and download success/failure/concurrency behavior.

The download checks use deterministic HTTP completion fixtures and an intentionally invalid URL to exercise immediate request failure. They do not contact external services. Godot reports an expected invalid-URL diagnostic and existing shutdown resource leaks; the runner separately rejects script errors, SQL errors, missing completion, and failed assertions.

For a rendered reader preview using a separate profile and an available display:

```sh
XDG_DATA_HOME=/tmp/scrollmapper-preview godot --path . --rendering-method gl_compatibility --audio-driver Dummy --windowed res://tests/regression.tscn -- --capture-reader
```

This saves normal, cross-reference, and focus-mode screenshots to `/tmp/scrollmapper-reader*.png`.


Launch-screen coverage also checks startup splash isolation, mouse routing for credit links, background/key dismissal, all five workspace card destinations, Home return routes, keyboard activation, and compact layout overflow.

To render the splash and menu at desktop and compact viewport sizes:

```sh
XDG_DATA_HOME=/tmp/scrollmapper-launch-preview godot --path . --rendering-method gl_compatibility --audio-driver Dummy --windowed res://tests/regression.tscn -- --capture-launch
```

This saves `/tmp/scrollmapper-splash*.png` and `/tmp/scrollmapper-menu*.png`. See `scenes/launch/README.md` for editor instructions and artwork sources.
