# Claude Code Status Line

A feature-rich status line for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that displays real-time context window usage, token counts, compaction history, and more.

## Preview

```
Sonnet 4.6  █████░░░░░░░░░░░░░░░ 26%  ↑34.7K ↓5.2K /200.0K  compact:0  my-project
```

### What it shows

| Section | Description |
|---|---|
| **Model name** | Current model (e.g. `Sonnet 4.6`, `Opus 4.7`) |
| **Progress bar** | 20-character visual bar showing context window usage |
| **Usage %** | Percentage of context window used |
| **Token counts** | Cumulative input (↑) and output (↓) tokens, with K formatting for thousands |
| **Context size** | Total context window size (e.g. `/200.0K`) |
| **Compact count** | Number of context compactions in this session (manual `/compact` + auto compaction) |
| **Directory name** | Basename of the current working directory |

### Color coding

- 🟢 **Green** — context usage < 50%
- 🟡 **Yellow** — context usage 50–80%
- 🔴 **Red** — context usage > 80%

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `jq` — JSON processor
- `bc` — basic calculator

### macOS

```bash
brew install jq bc
```

### Windows (WSL / Git Bash)

```bash
# WSL
sudo apt install jq bc

# Git Bash: install via MSYS2 or scoop
scoop install jq bc
```

## Installation

### 1. Download the script

```bash
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/baisiqi6/claude-code-statusline/main/statusline.sh
chmod +x ~/.claude/statusline.sh
```

### 2. Add to Claude Code settings

Edit `~/.claude/settings.json` and add the `statusLine` field:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

> **Note:** If you already have other settings in `settings.json`, just add the `statusLine` key alongside them. Do not replace the entire file.

### 3. Restart Claude Code

Start a new Claude Code session. The status line should appear at the bottom of the terminal.

## How it works

Claude Code pipes a JSON object to the status line script on stdin on each refresh. The script parses this data and outputs a formatted single-line string to stdout.

The JSON includes:
- Model name and display info
- Context window usage (percentage, token counts, window size)
- Session ID
- Current working directory

The compaction counter works by reading the session's JSONL log file (`~/.claude/projects/<scope>/<session_id>.jsonl`) and counting:
- `/compact` commands (manual compaction)
- "This session is being continued" messages (auto compaction triggered by context limit)

## Customization

Edit `~/.claude/statusline.sh` to customize:

- **Bar width** — change `bar_width=20` on line 46
- **Color thresholds** — adjust the percentage boundaries on lines 51–56
- **Display fields** — add or remove sections in the final `printf` on the last line
