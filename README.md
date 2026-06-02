# ☀️ GoodMorning

**GoodMorning** is a modular Bash launcher for small daily utilities.

The project is built around a simple structure: a single entry point, a central module registry, shared helper libraries, and independent modules that can be added or removed as needed.

It starts with a friendly prompt and offers a collection of configurable modules such as weather, crypto, news, backups etc. Each module is an independent shell script that can be run through the main application or directly from the command line.

## 🚀 Quick Start

Run the application from the project root:

```bash
bash main.sh
```
or
```bash
chmod +x main.sh
./main.sh
```

You can also run individual modules directly:

```bash
bash modules/weather.sh "New York" "Eiffel Tower"
bash modules/backup.sh
```

## 🏗️ Project Structure

```text
.
├── main.sh              # Application entry point
├── config.sh            # Configuration and module registry
├── libs/                # Shared libraries and utilities
└── modules/             # Feature modules
```
## 🏗️ How It Works

### `main.sh`

The application entry point.

### `config.sh`

Contains the module registry, shortcut definitions, and project settings.

### `libs/bootstrap.sh`

Loads and initializes shared project resources.

### `libs/tools.sh`

Provides reusable helper and utility functions used throughout the project.

### `modules/`

Contains the individual feature modules.

## ⚙️ Configuration

Most project settings live in `config.sh`.

Examples include:

* Enabled modules
* Module shortcuts
* Backup locations
* Crypto preferences
* User-facing messages

The application reads the module registry from `config.sh` and builds the menu dynamically.

## 🧩 How Modules Work

Modules are standalone scripts located in `modules/`.

Each module can:

* Run independently
* Use shared libraries through `bootstrap.sh`
* Declare its own dependencies
* Be added or removed without affecting other modules

Modules are registered through the `MODULES` array in `config.sh`.

Example:

```bash
"weather|weather|w|🌤️ Weather"
```

Format:

```text
script_name|shortcut1|shortcut2|Prompt Label
```
 ℹ️ You can add as many shortcuts as you want. A function on startup checks for duplicate shortcuts.

## ➕ Adding a Module

1. Copy `modules/0_template.sh` and rename to your new script name. Make sure the script lives in `modules/`.

2. Load the required libraries:

   ```bash
   source "$(dirname "${BASH_SOURCE[0]}")/../libs/bootstrap.sh"
   load_libs styles animations math
   ```

3. Set the script title.

	```bash
	set_title "🌤️  TITLE 🌤️"
	```

4. Register the module in `config.sh`:

   ```bash
   "notes|notes|n|📝 Notes"
   ```

5. Run the application:

   ```bash
   bash main.sh
   ```

Your new module will automatically appear in the launcher.

## 🎯 Project Goals

* Learn modern Bash development
* Build reusable shell libraries
* Keep modules independent
* Improve code quality over time
* Keep the project simple and maintainable
* Create practical terminal tools for everyday use

GoodMorning is an active learning project and is intentionally kept simple.

The focus is on modular Bash development, reusable libraries, and gradually improving code quality while adding new features.