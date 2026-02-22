# Claude Code Launcher

A Windows GUI launcher for managing and opening projects with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) via WSL.

## Features

- **Project list GUI** - Dark-themed Windows Forms interface to manage your projects
- **Auto-detect projects** - Automatically discovers new folders in `~/ClaudeProjects`
- **Add/remove projects** - Manually register projects from any WSL path
- **Path validation** - Validates that paths are absolute and exist before launching
- **Double-click to open** - Select a project and launch Claude Code in Windows Terminal
- **Desktop shortcut** - One-click shortcut with custom icon

## Requirements

- Windows 10/11 with WSL2 (Ubuntu)
- [Windows Terminal](https://aka.ms/terminal)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed in WSL (`~/.local/bin/claude`)
- PowerShell 5.1+

## Installation

1. Clone this repo into your WSL home directory:

```bash
git clone https://github.com/joaosggtl-gif/claude-launcher.git ~/.claude-launcher
```

2. Create a desktop shortcut (run in PowerShell on Windows):

```powershell
powershell -ExecutionPolicy Bypass -File "\\wsl$\Ubuntu\home\hike-\.claude-launcher\create-shortcut.ps1"
```

3. A "Claude SC" shortcut will appear on your desktop.

## Usage

1. Launch via the desktop shortcut or run directly:

```powershell
powershell -ExecutionPolicy Bypass -File "\\wsl$\Ubuntu\home\hike-\.claude-launcher\claude-launcher.ps1"
```

2. **Select a project** from the list and click **"Abrir com Claude"** (or double-click)
3. Claude Code opens in Windows Terminal at the project directory

### Managing projects

- **Adicionar Projeto** - Add a new project by name and WSL path
- **Deletar Projeto** - Remove a project from the list (does not delete files)
- Projects in `~/ClaudeProjects/` are auto-detected on launch

## File structure

```
.claude-launcher/
├── claude-launcher.ps1    # Main launcher GUI
├── create-icon.ps1        # Generates the .ico file
├── create-shortcut.ps1    # Creates desktop shortcut
├── projects.json          # Project registry
└── README.md
```

## Configuration

Projects are stored in `projects.json`:

```json
{
  "projects": [
    {
      "name": "my-project",
      "path": "/home/user/my-project"
    }
  ]
}
```

Edit `$configPath`, `$projectsDir`, and `$wslProjectsDir` at the top of `claude-launcher.ps1` to match your WSL setup.
