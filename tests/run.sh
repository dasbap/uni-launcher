#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export XDG_CONFIG_HOME="$TMP/xdg"
mkdir -p "$TMP/bin" "$TMP/games"

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "sortie attendue: $2"; }

cat > "$TMP/bin/fake-runner" <<'EOF'
#!/usr/bin/env bash
printf 'fake-runner'; printf ' [%s]' "$@"; printf '\n'
EOF
cat > "$TMP/bin/emu" <<'EOF'
#!/usr/bin/env bash
printf 'fake-emu'; printf ' [%s]' "$@"; printf '\n'
EOF
cat > "$TMP/games/native-game" <<'EOF'
#!/usr/bin/env bash
printf 'native-game\n'
EOF
chmod +x "$TMP/bin/fake-runner" "$TMP/bin/emu" "$TMP/games/native-game"
touch "$TMP/games/game.rom"
export PATH="$TMP/bin:$PATH"

bash -n "$ROOT/uni" "$ROOT"/lib/uni/*.bash "$ROOT/completions/uni.bash" "$ROOT/tests/run.sh"
empty_xdg="$TMP/empty"; output="$(XDG_CONFIG_HOME="$empty_xdg" "$ROOT/uni")"; assert_contains "$output" "Usage:"; [[ ! -e "$empty_xdg/uni" ]] || fail "l'aide ne doit pas creer la configuration"

"$ROOT/uni" --add-runner custom fake-runner >/dev/null
"$ROOT/uni" --add-game native "$TMP/games/native-game" >/dev/null
"$ROOT/uni" --add-game wrapped "$TMP/games/game.rom" >/dev/null
"$ROOT/uni" --link custom wrapped >/dev/null
"$ROOT/uni" --add-emu-game retro "$TMP/games/game.rom" >/dev/null

assert_contains "$("$ROOT/uni" --dry-run native -- --level 2)" "$TMP/games/native-game"
assert_contains "$("$ROOT/uni" --dry-run wrapped -- --fullscreen)" "$TMP/bin/fake-runner"
assert_contains "$("$ROOT/uni" --dry-run retro)" "$TMP/bin/emu"
assert_contains "$("$ROOT/uni" --dry-run emu mario)" "$TMP/bin/emu"
assert_contains "$("$ROOT/uni" --list)" "retro"
assert_contains "$("$ROOT/uni" doctor)" "OK runner emu"

TEST_HOME="$TMP/home"; mkdir -p "$TEST_HOME"
HOME="$TEST_HOME" "$ROOT/uni" --install >/dev/null
[[ -x "$TEST_HOME/.local/bin/uni" ]] || fail "uni non installe"
[[ -f "$TEST_HOME/.local/lib/uni/core.bash" ]] || fail "modules non installes"
[[ -f "$TEST_HOME/.local/lib/uni/install-update-launcher.bash" ]] || fail "bibliotheque d'installation partagee non installee"
[[ -f "$TEST_HOME/.local/share/bash-completion/completions/uni" ]] || fail "completion non installee"
HOME="$TEST_HOME" "$TEST_HOME/.local/bin/uni" --help >/dev/null

create_remote() {
  local directory="$1"
  git -C "$directory" init -q
  git -C "$directory" config user.name test
  git -C "$directory" config user.email test@example.invalid
  git -C "$directory" add -A
  git -C "$directory" commit -qm initial
  git -C "$directory" branch -M main
}

UNI_REMOTE="$TMP/uni-remote"
mkdir -p "$UNI_REMOTE/lib/uni" "$UNI_REMOTE/completions"
cp "$ROOT/uni" "$UNI_REMOTE/uni"
cp "$ROOT"/lib/uni/*.bash "$UNI_REMOTE/lib/uni/"
cp "$ROOT/completions/uni.bash" "$UNI_REMOTE/completions/uni.bash"
create_remote "$UNI_REMOTE"

EMU_REMOTE="$TMP/emu-remote"
mkdir -p "$EMU_REMOTE/lib/emu" "$EMU_REMOTE/completions"
cat > "$EMU_REMOTE/emu" <<'EOF'
#!/usr/bin/env bash
echo remote-emu
EOF
echo 'remote_emu=true' > "$EMU_REMOTE/lib/emu/core.bash"
echo 'complete -W help emu' > "$EMU_REMOTE/completions/emu.bash"
chmod +x "$EMU_REMOTE/emu"
create_remote "$EMU_REMOTE"

INSTALLER_REMOTE="$TMP/installer-remote"
mkdir -p "$INSTALLER_REMOTE/lib/install-update-launcher"
cat > "$INSTALLER_REMOTE/install-update-launcher" <<'EOF'
#!/usr/bin/env bash
echo remote-installer
EOF
cp "$ROOT/../install-update-launcher/lib/install-update-launcher/install-update-launcher.bash" \
  "$INSTALLER_REMOTE/lib/install-update-launcher/install-update-launcher.bash"
chmod +x "$INSTALLER_REMOTE/install-update-launcher"
create_remote "$INSTALLER_REMOTE"

REMOTE_HOME="$TMP/remote-home"; mkdir -p "$REMOTE_HOME"
HOME="$REMOTE_HOME" "$ROOT/uni" --install >/dev/null
HOME="$REMOTE_HOME" \
UNI_REPOSITORY="file://$UNI_REMOTE" \
EMU_REPOSITORY="file://$EMU_REMOTE" \
INSTALL_UPDATE_REPOSITORY="file://$INSTALLER_REMOTE" \
  "$REMOTE_HOME/.local/bin/uni" --update --all >/dev/null
[[ -x "$REMOTE_HOME/.local/bin/uni" ]] || fail "uni remote update failed"
[[ -x "$REMOTE_HOME/.local/bin/emu" ]] || fail "emu was not managed by uni --all"
[[ -x "$REMOTE_HOME/.local/bin/install-update-launcher" ]] || fail "installer was not managed by uni --all"

echo "All tests passed."
