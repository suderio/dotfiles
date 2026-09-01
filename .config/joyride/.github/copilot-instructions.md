---
description: 'Joyride User project — scripts and source files available across all VS Code windows'
applyTo: '**'
---

# Joyride User Project

This is your Joyride User project at `~/.config/joyride/`. Scripts and
source files here are available globally across all VS Code windows.

The Joyride extension bundles skills with comprehensive API documentation
and pattern guidance. These instructions focus on this project's specific
content.

## Project Inventory

- `scripts/user_activate.cljs` — Activation script, manages disposables
- `scripts/hello_joyride_user_script.cljs` — Example async dialog script
- `src/joy_button.cljs` — Status bar button with QuickPick menu

## Development

Use the REPL (`joyride_evaluate_code`) as your primary tool. Develop
incrementally, evaluate subexpressions, only update files when asked.
Prefer structural editing tools when editing Clojure files.

As new scripts and source files are added to this project, update the
inventory above.
