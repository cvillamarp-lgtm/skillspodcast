#!/usr/bin/env bash
set -euo pipefail

# Install Lenny's Product Skills for Claude Code
# Usage: ./install.sh [skill1 skill2 ...]
#        ./install.sh --list
#        ./install.sh --all (default)

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
TARGET_DIR=".claude/skills"

print_usage() {
  echo "Usage: $0 [OPTIONS] [skill1 skill2 ...]"
  echo ""
  echo "Options:"
  echo "  --all     Install all skills (default)"
  echo "  --list    List available skills"
  echo "  --help    Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                              # Install all skills"
  echo "  $0 writing-prds evaluating-candidates"
  echo "  $0 --list"
}

list_skills() {
  echo "Available skills:"
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"
    echo "  $skill_name"
  done
}

install_skill() {
  local skill_name="$1"
  local src="$SKILLS_DIR/$skill_name"

  if [[ ! -d "$src" ]]; then
    echo "Error: skill '$skill_name' not found" >&2
    return 1
  fi

  mkdir -p "$TARGET_DIR/$skill_name"
  cp -r "$src/." "$TARGET_DIR/$skill_name/"
  echo "  Installed: $skill_name"
}

main() {
  local install_all=true
  local skills_to_install=()

  # Parse arguments
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

  echo "Installing to $TARGET_DIR/"
  mkdir -p "$TARGET_DIR"

  if [[ "$install_all" == true ]]; then
    for skill_dir in "$SKILLS_DIR"/*/; do
      install_skill "$(basename "$skill_dir")"
    done
  else
    for skill in "${skills_to_install[@]}"; do
      install_skill "$skill"
    done
  fi

  echo ""
  echo "Done! Skills are ready in $TARGET_DIR/"
  echo "Start using them in Claude Code:"
  echo "  \"Help me write a PRD for our new feature\""
  echo "  \"I need to evaluate a PM candidate\""
}

main "$@"
