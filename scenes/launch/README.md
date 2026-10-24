# Launch screens

The application opens `splash.tscn` once at startup. Clicking the background or artwork, tapping, or pressing a key opens `main_menu.tscn`. Credit cards open their external destinations without dismissing the splash. Every existing `HOME` route returns to the main menu, so exiting a workspace does not replay the splash.

## Editing in Godot

- Open **splash.tscn** to edit the splash artwork, prompt, credit cards, and spacing.
- Open **main_menu.tscn** to edit the header, workspace grids, resource cards, and footer.
- Select a card instance to edit its **Title**, **Description**, **Category**, **Action Text**, **Artwork**, **Destination Level**, or **Destination URL** in the Inspector. Text and artwork update in the editor.
- Edit **feature_card.tscn** or **project_card.tscn** to change the reusable card layouts. All controls are saved scene nodes, including the labels, artwork, overlays, and margins.
- Edit **launch_theme.tres** for typography, colors, focus outlines, text shadows, button states, and scrollbars. Its styles are scoped to these launch scenes.
- Select the main menu or splash root to tune the exported responsive layout settings. The menu scrolls vertically and its existing grids reflow at narrow widths. No GUI controls are constructed by the runtime scripts.

The former 3D home scene remains at `res://scenes/home/home.tscn` for future use. Existing module scenes and their Home routes have been retained.

## Artwork sources

The project owner supplied and authorized these images. Copies are bundled locally; startup does not depend on network access.

- Splash: https://raw.githubusercontent.com/scrollmapper/bible_databases/refs/heads/master/docs/scrollmapper.png
- Card / Labs artwork: https://avatars.githubusercontent.com/u/302273712?s=400&u=34880bb4e9895ae8e376a1baf60a9ba0da0cda42&v=4

Credit and resource destinations are stored on each scene instance:

- Godot: https://godotengine.org/
- Bible Databases: https://github.com/scrollmapper/bible_databases
- Deuterocanonical Databases: https://github.com/scrollmapper/bible_databases_deuterocanonical
- Scrollmapper Labs: https://github.com/scrollmapper-labs
- Documentation: https://github.com/scrollmapper-labs/scrollmapper/blob/main/documentation/user/README.md
