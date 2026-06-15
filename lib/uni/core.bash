CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/uni"
RUNNERS_CONFIG="$CONFIG_DIR/runners"
GAMES_CONFIG="$CONFIG_DIR/games"

die() { echo "Erreur: ${1:-erreur}" >&2; exit "${2:-1}"; }

usage() {
  cat <<'EOF'
uni - lanceur universel de jeux et d'executables

Usage:
  uni --help|-h
  uni --list|-l
  uni [--foreground|-f] [--dry-run] [--verbose] <game-name> [-- <args>]
  uni [--foreground|-f] [--dry-run] [--verbose] <runner-name> [target] [-- <args>]
  uni [--foreground|-f] [--dry-run] [--verbose] <executable> [-- <args>]
  uni emu [<emu-args>]
  uni --add-runner <name> <command>
  uni --remove-runner <name>
  uni --add-game <name> <path>
  uni --add-emu-game <name> <rom>
  uni --link <runner-name> <game-name>
  uni --unlink <game-name>
  uni --remove-game <game-name>
  uni --set-emu <command>
  uni doctor
  uni launchers [--system] [--channel stable|prerelease|development] [--ref git-ref]
                [--installed|--missing|--current|--updates]
  uni --install [--system] [--channel stable|prerelease|development] [--ref git-ref] [--with-emu] [--all] | -i
  uni --update|-u [--system] [--channel stable|prerelease|development] [--ref git-ref]
                  [--merge-config] [--force-config]
  uni --clear-config

Les arguments places apres -- sont transmis sans modification.
Configuration: ~/.config/uni/runners et ~/.config/uni/games
EOF
}

valid_name() { [[ "$1" =~ ^[A-Za-z0-9_.-]+$ ]]; }

expand_path() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

resolve_command() {
  local raw="$1" expanded resolved
  expanded="$(expand_path "$raw")"
  if [[ "$expanded" != */* ]] && resolved="$(command -v "$expanded" 2>/dev/null)"; then
    printf '%s\n' "$resolved"
  elif command -v realpath >/dev/null 2>&1; then
    realpath -m "$expanded" 2>/dev/null || printf '%s\n' "$expanded"
  else
    printf '%s\n' "$expanded"
  fi
}

print_command() {
  local arg first=true
  for arg in "$@"; do
    [[ "$first" == true ]] || printf ' '
    printf '%q' "$arg"
    first=false
  done
  printf '\n'
}

log_verbose() {
  [[ "$VERBOSE" == true ]] && printf 'uni: %s\n' "$*" >&2 || true
}
