FOREGROUND=false
DRY_RUN=false
VERBOSE=false
newargs=()
passthrough=()

parse_global_args() {
  local after_separator=false arg
  newargs=(); passthrough=()
  for arg in "$@"; do
    if [[ "$after_separator" == true ]]; then passthrough+=("$arg"); continue; fi
    case "$arg" in
      --) after_separator=true ;;
      --foreground|-f) FOREGROUND=true ;;
      --dry-run) DRY_RUN=true ;;
      --verbose|-v) VERBOSE=true ;;
      *) newargs+=("$arg") ;;
    esac
  done
}

install_paths() {
  if [[ "$1" == true ]]; then
    printf '/usr/local/bin\n/usr/local/lib/uni\n/usr/local/share/bash-completion/completions\n'
  else
    printf '%s/.local/bin\n%s/.local/lib/uni\n%s/.local/share/bash-completion/completions\n' "$HOME" "$HOME" "$HOME"
  fi
}

configure_shells() {
  local completion="$HOME/.local/share/bash-completion/completions/uni"
  touch "$HOME/.profile" "$HOME/.bashrc"
  if ! grep -Fq '# >>> uni launcher PATH >>>' "$HOME/.profile"; then
    cat >> "$HOME/.profile" <<'EOF'

# >>> uni launcher PATH >>>
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
export PATH
# <<< uni launcher PATH <<<
EOF
  fi
  if ! grep -Fq '# >>> uni launcher >>>' "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" <<EOF

# >>> uni launcher >>>
case ":\$PATH:" in *":\$HOME/.local/bin:"*) ;; *) export PATH="\$HOME/.local/bin:\$PATH" ;; esac
[[ -f "$completion" ]] && source "$completion"
# <<< uni launcher <<<
EOF
  fi
}

install_uni() {
  local system="$1" paths dest lib_dest completion_dest
  paths="$(install_paths "$system")"; dest="${paths%%$'\n'*}"; paths="${paths#*$'\n'}"
  lib_dest="${paths%%$'\n'*}"; completion_dest="${paths#*$'\n'}"
  mkdir -p "$dest" "$lib_dest" "$completion_dest"
  rm -f "$dest/uni" "$lib_dest"/*.bash
  cp "$SCRIPT_DIR/uni" "$dest/uni"
  cp "$MODULE_DIR"/*.bash "$lib_dest/"
  cp "$SCRIPT_DIR/completions/uni.bash" "$completion_dest/uni"
  chmod +x "$dest/uni"
  [[ "$system" == true ]] || configure_shells
  echo "uni installe dans $dest/uni"
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi
}

copy_changed() {
  local src="$1" dst="$2" label="$3"
  if [[ -f "$dst" && "$(hash_file "$src")" == "$(hash_file "$dst")" ]]; then
    echo "Inchange $label"; return 1
  fi
  cp "$src" "$dst"; echo "Mis a jour $label"
}

update_uni() {
  local system="$1" paths dest lib_dest completion_dest module changed=false
  paths="$(install_paths "$system")"; dest="${paths%%$'\n'*}"; paths="${paths#*$'\n'}"
  lib_dest="${paths%%$'\n'*}"; completion_dest="${paths#*$'\n'}"
  mkdir -p "$dest" "$lib_dest" "$completion_dest"
  copy_changed "$SCRIPT_DIR/uni" "$dest/uni" "commande" && { chmod +x "$dest/uni"; changed=true; } || true
  for module in "$MODULE_DIR"/*.bash; do copy_changed "$module" "$lib_dest/$(basename "$module")" "$(basename "$module")" && changed=true || true; done
  copy_changed "$SCRIPT_DIR/completions/uni.bash" "$completion_dest/uni" "completion Bash" && changed=true || true
  [[ "$changed" == true ]] || echo "uni est deja a jour"
}

list_library() {
  local line key value runner
  echo "Runners:"
  while IFS= read -r line; do printf '  %s -> %s\n' "${line%%=*}" "${line#*=}"; done < <(cfg_pairs "$RUNNERS_CONFIG")
  echo "Games:"
  while IFS= read -r line; do
    key="${line%%=*}"; value="${line#*=}"
    [[ "$key" == *.__resolved || "$key" == *.__runner ]] && continue
    runner="$(cfg_get "$GAMES_CONFIG" "$key.__runner")"
    printf '  %s -> %s' "$key" "$value"
    [[ -z "$runner" ]] || printf ' [%s]' "$runner"
    printf '\n'
  done < <(cfg_pairs "$GAMES_CONFIG")
}

handle_command() {
  local name value resolved runner game removed system backup
  case "${1:-}" in
    --list|-l) list_library; exit 0 ;;
    --add-runner)
      [[ -n "${2:-}" && -n "${3:-}" ]] || die "Usage: uni --add-runner <name> <command>"
      name="$2"; value="$3"; valid_name "$name" || die "Nom de runner invalide: $name"
      cfg_has "$RUNNERS_CONFIG" "$name" && die "Le runner '$name' existe deja" 2
      cfg_set "$RUNNERS_CONFIG" "$name" "$value"; echo "Runner '$name' ajoute -> $value"; exit 0 ;;
    --remove-runner)
      name="${2:-}"; [[ -n "$name" ]] || die "Usage: uni --remove-runner <name>"
      cfg_has "$RUNNERS_CONFIG" "$name" || die "Runner '$name' introuvable" 2
      cfg_delete "$RUNNERS_CONFIG" "$name" || true; removed="$(remove_runner_links "$name")"
      echo "Runner '$name' supprime; $removed lien(s) retire(s)"; exit 0 ;;
    --add-game|--add-emu-game)
      [[ -n "${2:-}" && -n "${3:-}" ]] || die "Usage: uni $1 <name> <path>"
      name="$2"; value="$3"; valid_name "$name" || die "Nom de jeu invalide: $name"
      cfg_has "$GAMES_CONFIG" "$name" && die "Le jeu '$name' existe deja" 2
      resolved="$(resolve_command "$value")"; cfg_set "$GAMES_CONFIG" "$name" "$value"; cfg_set "$GAMES_CONFIG" "$name.__resolved" "$resolved"
      [[ "$1" == --add-emu-game ]] && cfg_set "$GAMES_CONFIG" "$name.__runner" emu
      echo "Jeu '$name' ajoute -> $value"; exit 0 ;;
    --link)
      runner="${2:-}"; game="${3:-}"; [[ -n "$runner" && -n "$game" ]] || die "Usage: uni --link <runner> <game>"
      cfg_has "$RUNNERS_CONFIG" "$runner" || die "Runner '$runner' introuvable" 2
      cfg_has "$GAMES_CONFIG" "$game" || die "Jeu '$game' introuvable" 2
      cfg_set "$GAMES_CONFIG" "$game.__runner" "$runner"; echo "Jeu '$game' lie a '$runner'"; exit 0 ;;
    --unlink)
      game="${2:-}"; cfg_has "$GAMES_CONFIG" "$game" || die "Jeu '$game' introuvable" 2
      cfg_delete "$GAMES_CONFIG" "$game.__runner" || true; echo "Jeu '$game' delie"; exit 0 ;;
    --remove-game)
      game="${2:-}"; cfg_has "$GAMES_CONFIG" "$game" || die "Jeu '$game' introuvable" 2
      cfg_delete "$GAMES_CONFIG" "$game" || true; cfg_delete "$GAMES_CONFIG" "$game.__resolved" || true; cfg_delete "$GAMES_CONFIG" "$game.__runner" || true
      echo "Jeu '$game' supprime"; exit 0 ;;
    --set-emu)
      [[ -n "${2:-}" ]] || die "Usage: uni --set-emu <command>"
      cfg_set "$RUNNERS_CONFIG" emu "$2"; echo "Runner emu configure -> $2"; exit 0 ;;
    doctor) doctor; exit $? ;;
    --install|-i) system=false; [[ "${2:-}" == --system ]] && system=true; install_uni "$system"; exit 0 ;;
    --update) system=false; [[ "${2:-}" == --system ]] && system=true; update_uni "$system"; exit 0 ;;
    --clear-config)
      backup="$CONFIG_DIR/backup.$(date +%s)"; mkdir -p "$backup"; cp "$RUNNERS_CONFIG" "$GAMES_CONFIG" "$backup/"; rm -f "$RUNNERS_CONFIG" "$GAMES_CONFIG"
      echo "Configuration sauvegardee dans $backup puis supprimee"; exit 0 ;;
  esac
}

doctor() {
  local status=0 line key value resolved runner
  echo "uni doctor"
  while IFS= read -r line; do
    key="${line%%=*}"; value="${line#*=}"; resolved="$(resolve_command "$value")"
    if [[ -x "$resolved" ]]; then echo "OK runner $key -> $resolved"; else echo "FAIL runner $key -> $value"; status=1; fi
  done < <(cfg_pairs "$RUNNERS_CONFIG")
  while IFS= read -r line; do
    key="${line%%=*}"; value="${line#*=}"; [[ "$key" == *.__* ]] && continue
    resolved="$(cfg_get "$GAMES_CONFIG" "$key.__resolved")"; runner="$(cfg_get "$GAMES_CONFIG" "$key.__runner")"
    if [[ -e "$resolved" || -x "$resolved" ]]; then echo "OK game $key -> $resolved"; else echo "FAIL game $key -> $value"; status=1; fi
    if [[ -n "$runner" ]] && ! cfg_has "$RUNNERS_CONFIG" "$runner"; then echo "FAIL game $key: runner '$runner' introuvable"; status=1; fi
  done < <(cfg_pairs "$GAMES_CONFIG")
  return "$status"
}

launch_from_args() {
  local input target runner executable game_path
  input="$1"; shift || true
  if cfg_has "$GAMES_CONFIG" "$input"; then
    game_path="$(cfg_get "$GAMES_CONFIG" "$input.__resolved")"; runner="$(cfg_get "$GAMES_CONFIG" "$input.__runner")"
    if [[ -n "$runner" ]]; then executable="$(runner_command "$runner")"; run_command "$executable" "$game_path" "$@" "${passthrough[@]}"; return; fi
    [[ -x "$game_path" ]] || die "Le jeu '$input' n'est pas executable et n'a aucun runner" 2
    run_command "$game_path" "$@" "${passthrough[@]}"; return
  fi
  if cfg_has "$RUNNERS_CONFIG" "$input"; then
    executable="$(runner_command "$input")"
    if [[ $# -gt 0 ]]; then target="$1"; shift; run_command "$executable" "$target" "$@" "${passthrough[@]}"; else run_command "$executable" "${passthrough[@]}"; fi
    return
  fi
  executable="$(resolve_command "$input")"
  [[ -x "$executable" ]] || die "Executable, runner ou jeu introuvable: $input" 2
  run_command "$executable" "$@" "${passthrough[@]}"
}

uni_main() {
  parse_global_args "$@"; set -- "${newargs[@]}"
  if [[ $# -eq 0 || "${1:-}" == --help || "${1:-}" == -h ]]; then usage; exit 0; fi
  ensure_config
  handle_command "$@"
  launch_from_args "$@"
}
