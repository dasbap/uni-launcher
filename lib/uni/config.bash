ensure_config() {
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$RUNNERS_CONFIG" ]]; then
    cat > "$RUNNERS_CONFIG" <<'EOF'
# name=command
emu=emu
EOF
  fi
  [[ -f "$GAMES_CONFIG" ]] || touch "$GAMES_CONFIG"
}

cfg_get() {
  local file="$1" key="$2" line
  [[ -f "$file" ]] || return 0
  while IFS= read -r line; do
    [[ "$line" == "$key="* ]] || continue
    printf '%s\n' "${line#*=}"
    return 0
  done < "$file"
}

cfg_has() { [[ -n "$(cfg_get "$1" "$2")" ]]; }

cfg_set() {
  local file="$1" key="$2" value="$3" tmp found=false line
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  while IFS= read -r line; do
    if [[ "$line" == "$key="* ]]; then
      printf '%s=%s\n' "$key" "$value" >> "$tmp"
      found=true
    else
      printf '%s\n' "$line" >> "$tmp"
    fi
  done < "$file"
  [[ "$found" == true ]] || printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$file"
}

cfg_delete() {
  local file="$1" key="$2" tmp line deleted=false
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  while IFS= read -r line; do
    if [[ "$line" == "$key="* ]]; then deleted=true; continue; fi
    printf '%s\n' "$line" >> "$tmp"
  done < "$file"
  mv "$tmp" "$file"
  [[ "$deleted" == true ]]
}

cfg_pairs() {
  local line
  [[ -f "$1" ]] || return 0
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# || "$line" != *=* ]] && continue
    printf '%s\n' "$line"
  done < "$1"
}

remove_runner_links() {
  local runner="$1" tmp line key value count=0
  tmp="$(mktemp "${GAMES_CONFIG}.tmp.XXXXXX")"
  while IFS= read -r line; do
    key="${line%%=*}"; value="${line#*=}"
    if [[ "$key" == *.__runner && "$value" == "$runner" ]]; then
      ((count += 1))
      continue
    fi
    printf '%s\n' "$line" >> "$tmp"
  done < "$GAMES_CONFIG"
  mv "$tmp" "$GAMES_CONFIG"
  printf '%s\n' "$count"
}
