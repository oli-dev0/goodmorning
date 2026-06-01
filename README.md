# ☀️ GoodMorning

**GoodMorning** is a modular Bash launcher for small daily utilities.

The project is built around a simple structure: a single entry point, a central module registry, shared helper libraries, and independent modules that can be added or removed as needed.

## 🚀 Quick Start

Run the application:

```bash
bash main.sh
```

or

```bash
chmod +x main.sh
./main.sh
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

## ➕ Adding a Module

1. Create a new script inside `modules/`
2. Register the module in `config.sh`
3. Run the application

```bash
bash main.sh
```

The new module will automatically become available through the launcher.

## 🎯 Project Goals

* Learn modern Bash development
* Build reusable shell libraries
* Keep modules independent
* Improve code quality over time
* Keep the project simple and maintainable

GoodMorning is an active learning project and is intentionally kept simple.

The focus is on modular Bash development, reusable libraries, and gradually improving code quality while adding new features.
