#!/usr/bin/env python3
"""Run Godot integration checks without touching the user's Scrollmapper profile."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

project = Path(__file__).resolve().parents[1]
godot = shutil.which("godot") or shutil.which("godot4")
if not godot:
    raise SystemExit("Godot 4 with the project's SQLite extension is required.")

with tempfile.TemporaryDirectory(prefix="scrollmapper-regression-", dir="/tmp") as profile:
    env = dict(os.environ, XDG_DATA_HOME=profile)
    # Import resources and register script classes for a clean checkout.
    imported = subprocess.run(
        [godot, "--headless", "--path", str(project), "--editor", "--quit"],
        env=env, capture_output=True, text=True, timeout=120,
    )
    if imported.returncode or "SCRIPT ERROR:" in imported.stdout + imported.stderr:
        print(imported.stdout + imported.stderr)
        raise SystemExit(1)
    tested = subprocess.run(
        [godot, "--headless", "--path", str(project), "res://tests/regression.tscn"],
        env=env, capture_output=True, text=True, timeout=120,
    )
    output = tested.stdout + tested.stderr
    for line in output.splitlines():
        if line.startswith(("PASS:", "FAIL:", "REGRESSION RESULT:")):
            print(line)
    match = re.search(r"REGRESSION RESULT: (\d+) checks, (\d+) failures", output)
    if tested.returncode or not match or int(match[2]) or "SCRIPT ERROR:" in output or "Error executing query:" in output:
        print(output)
        raise SystemExit(1)
    print("Passed in an isolated temporary profile.")
