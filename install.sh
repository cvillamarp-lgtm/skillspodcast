#!/usr/bin/env bash
set -euo pipefail

# Install Lenny's Product Skills for Claude Code
# Usage: ./install.sh [skill1 skill2 ...]
#        ./install.sh --list
#        ./install.sh --no-extras   (skip CLAUDE.md, commands, hooks)
#        ./install.sh --all (default)
#
# One-liner remote install:
#   curl -fsSL https://raw.githubusercontent.com/cvillamarp-lgtm/skillspodcast/master/install.sh | bash

REPO_URL="https://github.com/cvillamarp-lgtm/skillspodcast.git"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If running piped from curl, skills dir won't exist — clone to a temp dir first
if [[ ! -d "$REPO_DIR/skills" ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  echo "Downloading Lenny's Product Skills..."
  git clone --depth=1 --quiet "$REPO_URL" "$TMP_DIR"
  REPO_DIR="$TMP_DIR"
fi

SKILLS_DIR="$REPO_DIR/skills"
TARGET_SKILLS_DIR=".claude/skills"
TARGET_COMMANDS_DIR=".claude/commands"
SETTINGS_FILE=".claude/settings.json"

print_usage() {
  echo "Usage: $0 [OPTIONS] [skill1 skill2 ...]"
  echo ""
  echo "Options:"
  echo "  --all        Install all skills + commands + CLAUDE.md + hooks (default)"
  echo "  --no-extras  Install skills only (no commands, CLAUDE.md, or hooks)"
  echo "  --list       List available skills"
  echo "  --help       Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Install everything"
  echo "  $0 writing-prds evaluating-candidates # Install specific skills + extras"
  echo "  $0 --no-extras writing-prds           # Skills only"
  echo "  $0 --list"
}

list_skills() {
  echo "Available skills:"
  for skill_dir in "$SKILLS_DIR"/*/; do
    echo "  $(basename "$skill_dir")"
  done
}

install_skill() {
  local skill_name="$1"
  local src="$SKILLS_DIR/$skill_name"

  if [[ ! -d "$src" ]]; then
    echo "  Error: skill '$skill_name' not found" >&2
    return 1
  fi

  mkdir -p "$TARGET_SKILLS_DIR/$skill_name"
  cp -r "$src/." "$TARGET_SKILLS_DIR/$skill_name/"
  echo "  [skill] $skill_name"
}

install_commands() {
  if [[ ! -d "$REPO_DIR/.claude/commands" ]]; then
    return
  fi
  mkdir -p "$TARGET_COMMANDS_DIR"
  cp "$REPO_DIR/.claude/commands/"*.md "$TARGET_COMMANDS_DIR/"
  echo ""
  echo "  [commands] /prd /prioritize /user-interview /evaluate-candidate"
  echo "             /stakeholder /okrs /pmf /ship /competitive"
  echo "             /difficult-conversation /north-star /ideate"
}

install_claude_md() {
  if [[ ! -f "$REPO_DIR/CLAUDE.md" ]]; then
    return
  fi
  if [[ -f "CLAUDE.md" ]]; then
    echo ""
    echo "  [CLAUDE.md] Already exists — appending Lenny Skills section..."
    echo "" >> CLAUDE.md
    cat "$REPO_DIR/CLAUDE.md" >> CLAUDE.md
  else
    cp "$REPO_DIR/CLAUDE.md" CLAUDE.md
    echo ""
    echo "  [CLAUDE.md] Created"
  fi
}

install_hooks() {
  if [[ ! -f "$REPO_DIR/.claude/settings.json" ]]; then
    return
  fi
  mkdir -p .claude
  if [[ -f "$SETTINGS_FILE" ]]; then
    echo ""
    echo "  [hooks] $SETTINGS_FILE already exists — skipping (merge manually if needed)"
    echo "          Reference: $REPO_DIR/.claude/settings.json"
  else
    cp "$REPO_DIR/.claude/settings.json" "$SETTINGS_FILE"
    echo ""
    echo "  [hooks] SessionStart hook installed in $SETTINGS_FILE"
  fi
}

main() {
  local install_all=true
  local install_extras=true
  local skills_to_install=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        print_usage
        exit 0
        ;;
      --list|-l)
        list_skills
        exit 0
        ;;
      --all)
        install_all=true
        shift
        ;;
      --no-extras)
        install_extras=false
        shift
        ;;
      -*)
        echo "Unknown option: $1" >&2
        print_usage >&2
        exit 1
        ;;
      *)
        install_all=false
        skills_to_install+=("$1")
        shift
        ;;
    esac
  done

  echo "Installing Lenny's Product Skills for Claude Code..."
  echo ""
  mkdir -p "$TARGET_SKILLS_DIR"

  if [[ "$install_all" == true ]]; then
    for skill_dir in "$SKILLS_DIR"/*/; do
      install_skill "$(basename "$skill_dir")"
    done
  else
    for skill in "${skills_to_install[@]}"; do
      install_skill "$skill"
    done
  fi

  if [[ "$install_extras" == true ]]; then
    install_commands
    install_claude_md
    install_hooks
  fi

  echo ""
  echo "Done!"
  echo ""
  echo "Try it in Claude Code:"
  echo "  /prd"
  echo "  /prioritize"
  echo "  \"Help me evaluate this PM candidate\""
}

main "$@"
