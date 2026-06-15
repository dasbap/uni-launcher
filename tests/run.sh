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

echo "All tests passed."
