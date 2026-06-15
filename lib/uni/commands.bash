FOREGROUND=false
DRY_RUN=false
VERBOSE=false
newargs=()
passthrough=()

source "$MODULE_DIR/installer.bash"

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
    launchers) list_available_launchers "${@:2}"; exit 0 ;;
    doctor) doctor; exit $? ;;
    --install|-i) handle_package_operation install "${@:2}"; exit 0 ;;
    --update) handle_package_operation update "${@:2}"; exit 0 ;;
    --clear-config)
      backup="$CONFIG_DIR/backup.$(date +%s)"; mkdir -p "$backup"; cp "$RUNNERS_CONFIG" "$GAMES_CONFIG" "$backup/"; rm -f "$RUNNERS_CONFIG" "$GAMES_CONFIG"
      echo "Configuration sauvegardee dans $backup puis supprimee"; exit 0 ;;
  esac
}

launcher_status_matches() {
  local status="$1" filter_installed="$2" filter_missing="$3" filter_current="$4" filter_updates="$5"
  if [[ "$filter_installed" == false && "$filter_missing" == false && \
        "$filter_current" == false && "$filter_updates" == false ]]; then
    return 0
  fi
  [[ "$filter_installed" == true && "$status" != not-installed && "$status" != unavailable ]] && return 0
  [[ "$filter_missing" == true && "$status" == not-installed ]] && return 0
  [[ "$filter_current" == true && "$status" == up-to-date ]] && return 0
  [[ "$filter_updates" == true && "$status" == update-available ]] && return 0
  return 1
}

list_available_launchers() {
  local system=false channel="$UNI_CHANNEL" ref="$UNI_REF" option status
  local filter_installed=false filter_missing=false filter_current=false filter_updates=false
  while [[ $# -gt 0 ]]; do
    option="$1"; shift
    case "$option" in
      --system) system=true ;;
      --channel) [[ $# -gt 0 ]] || die "--channel requires a value" 2; channel="$1"; shift ;;
      --ref) [[ $# -gt 0 ]] || die "--ref requires a value" 2; ref="$1"; shift ;;
      --installed) filter_installed=true ;;
      --missing) filter_missing=true ;;
      --current) filter_current=true ;;
      --updates) filter_updates=true ;;
      *) die "unknown launchers option: $option" 2 ;;
    esac
  done
  configure_deployment_refs "$channel" "$ref"
  printf 'Available launchers (channel: %s, ref: %s)\n' "$channel" "$UNI_REF"
  printf '%-26s %-18s %s\n' NAME STATUS REPOSITORY

  status="$(launcher_package_status emu "$system")"
  launcher_status_matches "$status" "$filter_installed" "$filter_missing" "$filter_current" "$filter_updates" && \
    printf '%-26s %-18s %s\n' emu "$status" "$EMU_REPOSITORY"
  status="$(launcher_package_status installer "$system")"
  launcher_status_matches "$status" "$filter_installed" "$filter_missing" "$filter_current" "$filter_updates" && \
    printf '%-26s %-18s %s\n' install-update-launcher "$status" "$INSTALL_UPDATE_REPOSITORY"
  cleanup_installer_checkout
}

handle_package_operation() {
  local action="$1" system=false with_emu=false option channel="$UNI_CHANNEL" ref="$UNI_REF"
  shift
  while [[ $# -gt 0 ]]; do
    option="$1"; shift
    case "$option" in
      --system) system=true ;;
      --channel) [[ $# -gt 0 ]] || die "--channel requires a value" 2; channel="$1"; shift ;;
      --ref) [[ $# -gt 0 ]] || die "--ref requires a value" 2; ref="$1"; shift ;;
      --with-installer) : ;; # Kept for compatibility; the installer is always managed.
      --with-emu) with_emu=true ;;
      --all) with_emu=true ;;
      *) die "unknown $action option: $option" 2 ;;
    esac
  done

  configure_deployment_refs "$channel" "$ref"

  manage_launcher_package "$action" installer "$system"
  if [[ "$action" == install ]]; then
    install_uni "$system"
  else
    update_uni "$system"
  fi
  [[ "$with_emu" == false ]] || manage_launcher_package "$action" emu "$system"
  cleanup_installer_checkout
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
