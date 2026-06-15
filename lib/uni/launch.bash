run_command() {
  local cmd=("$@")
  log_verbose "foreground=$FOREGROUND dry_run=$DRY_RUN"
  log_verbose "command: $(print_command "${cmd[@]}")"
  if [[ "$DRY_RUN" == true ]]; then
    print_command "${cmd[@]}"
    exit 0
  fi
  if [[ "$FOREGROUND" == true ]]; then
    exec "${cmd[@]}"
  fi
  if command -v setsid >/dev/null 2>&1; then
    setsid "${cmd[@]}" >/dev/null 2>&1 &
  elif command -v nohup >/dev/null 2>&1; then
    nohup "${cmd[@]}" >/dev/null 2>&1 &
  else
    "${cmd[@]}" >/dev/null 2>&1 &
  fi
  disown >/dev/null 2>&1 || true
  echo "Lance ${cmd[0]} en arriere-plan."
}

runner_command() {
  local name="$1" configured resolved
  configured="$(cfg_get "$RUNNERS_CONFIG" "$name")"
  [[ -n "$configured" ]] || return 1
  resolved="$(resolve_command "$configured")"
  [[ -x "$resolved" ]] || die "Runner '$name' introuvable ou non executable: $configured" 2
  printf '%s\n' "$resolved"
}
