# ☀️ GoodMorning

**GoodMorning** is a modular Bash launcher for small daily utilities.

The project is built around a simple structure: multiple entry points, a central module registry, shared helper libraries, and independent modules that can be added or removed as needed.

It starts with a friendly prompt and offers a collection of configurable modules, such as weather, crypto, news, backups, and more. Each module is an independent shell script that can be run through several launchers, or directly from the command line

## 🚀 Quick Start

**GoodMorning** includes four launchers: a prompt-based terminal CLI, a Bash `select` menu, an `fzf` searchable menu, and a dialog-based terminal GUI. You can run any version from the project root.

Terminal CLI: 
```bash
bash main.sh
# or
chmod +x main.sh
./main.sh
```

Terminal select menu:
```bash
bash main_select.sh
# or
chmod +x main_select.sh
./main_select.sh
```

Searchable fzf menu:
```bash
bash main_fzf.sh
# or
chmod +x main_fzf.sh
./main_fzf.sh
```
ℹ️ The fzf version requires `fzf` to be installed.

Terminal GUI:
```bash
bash main_gui.sh
# or
chmod +x main_gui.sh
./main_gui.sh
```
ℹ️ The GUI version requires `dialog` to be installed.

You can also run individual modules directly:

```bash
bash modules/weather.sh "New York" 
bash modules/weather.sh "Eiffel Tower"
bash modules/backup.sh
```

## 📦 Requirements

**GoodMorning** is designed for Bash-based Linux systems.

Required tools depend on which modules are enabled. The launcher validates the module registry at startup, and each module checks its own command dependencies before running.

Common dependencies include:

* `bash` 4+
* `curl`, `wget`, `httpie`, or `fetch` for HTTP requests
* `jq`
* `tar`
* `stat`
* `numfmt`
* `pv` for live backup progress bars
* `gzip`
* `ssh`
* `rsync`
* `fzf` for the searchable terminal menu
* `dialog` for the terminal GUI version

## 🏗️ Project Structure

```text
.
├── main.sh              # Prompt-based terminal launcher
├── main_select.sh       # Bash select-menu launcher
├── main_fzf.sh          # fzf searchable menu launcher
├── main_gui.sh          # Dialog-based GUI launcher
├── config.sh            # Configuration and module registry
├── libs/                # Shared libraries and utilities
└── modules/             # Individual feature modules
```

## ⚙️ Configuration

Most project settings live in `config.sh`.

Examples include:

* Enabled modules
* Module display names
* Module descriptions
* Module shortcuts
* Backup locations
* Crypto preferences
* User-facing messages

The application reads the module registry from `config.sh` and builds the terminal launchers and GUI menu dynamically.

## 🧩 How Modules Work

Modules are standalone scripts located in `modules/`.

Each module can:

* Run through `main.sh`
* Run through `main_select.sh`
* Run through `main_fzf.sh`
* Run through `main_gui.sh`
* Run independently with `bash modules/module_name.sh`
* Use shared libraries through `bootstrap.sh`
* Declare its own dependencies
* Be added or removed without affecting other modules

Modules are registered through the `GM_MODULES` array in `config.sh`.

## 🧾 Module Registry Format

Each module entry uses pipe-separated fields:

```text
module_name|Display Name|Description|shortcut1|shortcut2|shortcut3...
```

Example:

```bash
GM_MODULES=(
   "weather|☁️ Weather|Show the current weather forecast|w|wt"
   "backup|💾 Backup|Create a backup archive|b"
   "crypto|🪙 Crypto|Show crypto prices|c"
)
```

### Field Meaning

```text
field 0 = module script name, without .sh
field 1 = display name shown in menus
field 2 = description shown in the GUI help text
field 3+ = optional shortcuts
```

Example:

```bash
"weather|☁️ Weather forecast|Show the current weather forecast for any location|w|wt"
```

Means:

```text
module script = modules/weather.sh
display name  = ☁️ Weather forecast
description   = Show the current weather forecast for any location
shortcuts     = w, wt
```
ℹ️ Additional details:

* You can add as many shortcuts as you want. A function on startup checks for duplicate shortcuts.
* Only the first field, the module name, is required. The remaining fields are optional, and the parser provides fallbacks when they are missing.

## ➕ Adding a Module

1. Copy `modules/0_template.sh` and rename to your new script name. The template already includes the bootstrap setup.
Make sure the script lives in `modules/`.

2. Set the script title:

   ```bash
   set_title "🌤️  NOTES 🌤️"
   ```

3. Set the required commands:

   ```bash
   required_commands jq
   ```

4. Register the module in `config.sh`:

   ```bash
   "notes|📝 Notes|Open the notes module|n"
   ```

5. Run the application:

   ```bash
   bash main.sh
   # or
   bash main_select.sh
   # or
   bash main_fzf.sh
   # or
   bash main_gui.sh
   ```

Your new module will automatically appear in the launcher.

## 🛡️ Validation

**GoodMorning** validates configured modules and duplicate shortcuts at startup. Each module also checks its own command dependencies before running.

## 🎯 Project Goals

* Learn modern Bash development
* Build reusable shell libraries
* Keep modules independent
* Support multiple terminal workflows
* Keep configuration centralized
* Improve code quality over time
* Create practical terminal tools for everyday use
* Keep the project simple and maintainable


**GoodMorning** is an active learning project focused on modular Bash development, reusable libraries, practical terminal tools, and gradually improving code quality while adding new features.
