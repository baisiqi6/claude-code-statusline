#!/bin/bash
# Claude Code Status Line
# Reads JSON from stdin, outputs formatted status bar
# Dependencies: jq, bc

read -r json

model=$(echo "$json" | jq -r '.model.display_name // "unknown"')
pct=$(echo "$json" | jq -r '.context_window.used_percentage // 0')
pct_int=$(printf "%.0f" "$pct")
in_tok=$(echo "$json" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$json" | jq -r '.context_window.total_output_tokens // 0')
max_ctx=$(echo "$json" | jq -r '.context_window.context_window_size // 200000')
session_id=$(echo "$json" | jq -r '.session_id // "default"')
cwd=$(echo "$json" | jq -r '.workspace.current_dir // empty')

# --- Compaction detection (from JSONL log) ---
# Only count real events by anchoring to line-start patterns
# - "<command-name>/compact" = manual /compact
# - "This session is being continued" = auto compaction (ran out of context)
# Filters out mentions in conversation text and tool outputs

claude_dir="$HOME/.claude"
# Find the project scope directory that contains this session's JSONL
jsonl=""
for proj_dir in "$claude_dir"/projects/*/; do
  candidate="${proj_dir}${session_id}.jsonl"
  if [ -f "$candidate" ]; then
    jsonl="$candidate"
    break
  fi
done

count=0
if [ -n "$jsonl" ]; then
  count=$(jq -r 'select(.type=="user") | .message.content | select(type=="string")' "$jsonl" 2>/dev/null \
    | grep -c -E '^<command-name>/compact|^This session is being continued' 2>/dev/null || true)
fi

# Format token counts (K for thousands)
format_tok() {
  local n=$1
  if [ "$n" -ge 1000 ]; then
    printf "%.1fK" "$(echo "scale=1; $n/1000" | bc)"
  else
    echo "${n}"
  fi
}

in_fmt=$(format_tok "$in_tok")
out_fmt=$(format_tok "$out_tok")
max_fmt=$(format_tok "$max_ctx")

# Progress bar (20 chars wide)
bar_width=20
filled=$(( pct_int * bar_width / 100 ))
if [ "$filled" -gt "$bar_width" ]; then
  filled=$bar_width
fi
empty=$(( bar_width - filled ))

bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# Color based on usage
if [ "$pct_int" -lt 50 ]; then
  color="\033[32m"
elif [ "$pct_int" -lt 80 ]; then
  color="\033[33m"
else
  color="\033[31m"
fi
reset="\033[0m"
dim="\033[2m"

dir_suffix=""
if [ -n "$cwd" ]; then
  dir_suffix="  ${dim}$(basename "$cwd")${reset}"
fi

printf "${dim}${model}${reset}  ${color}${bar}${reset} ${pct_int}%%  ${dim}↑${in_fmt} ↓${out_fmt} /${max_fmt}  compact:${count}${reset}${dir_suffix}"
