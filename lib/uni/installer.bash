find_install_update_library() {
  local candidate
  for candidate in \
    "${INSTALL_UPDATE_LAUNCHER_LIB:-}" \
    "$MODULE_DIR/install-update-launcher.bash" \
    "$SCRIPT_DIR/../install-update-launcher/lib/install-update-launcher/install-update-launcher.bash" \
    "$HOME/.local/lib/install-update-launcher/install-update-launcher.bash" \
    /usr/local/lib/install-update-launcher/install-update-launcher.bash; do
    [[ -n "$candidate" && -f "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  done
  return 1
}

UNI_REPOSITORY="${UNI_REPOSITORY:-https://github.com/dasbap/uni-launcher.git}"
UNI_CHANNEL="${UNI_CHANNEL:-stable}"
UNI_REF="${UNI_REF:-}"
EMU_REPOSITORY="${EMU_REPOSITORY:-https://github.com/dasbap/emu-launcher.git}"
EMU_REF="${EMU_REF:-}"
INSTALL_UPDATE_REPOSITORY="${INSTALL_UPDATE_REPOSITORY:-https://github.com/dasbap/install-update-launcher.git}"
INSTALL_UPDATE_REF="${INSTALL_UPDATE_REF:-}"
INSTALL_UPDATE_CHECKOUT=""

load_install_update_library() {
  local library
  if library="$(find_install_update_library)"; then
    source "$library"
    return 0
  fi
  command -v git >/dev/null 2>&1 || die "git is required to download install-update-launcher" 1
  INSTALL_UPDATE_CHECKOUT="$(mktemp -d)"
  git clone --quiet --depth 1 --branch "$INSTALL_UPDATE_REF" \
    "$INSTALL_UPDATE_REPOSITORY" "$INSTALL_UPDATE_CHECKOUT" || \
    die "unable to download install-update-launcher" 1
  source "$INSTALL_UPDATE_CHECKOUT/lib/install-update-launcher/install-update-launcher.bash"
}

deployment_channel_ref() {
  case "$1" in
    stable) printf 'release\n' ;;
    prerelease) printf 'pre-release\n' ;;
    development) printf 'main\n' ;;
    *) die "unknown deployment channel: $1" 2 ;;
  esac
}

configure_deployment_refs() {
  local channel="$1" ref="$2"
  [[ -n "$ref" ]] || ref="$(deployment_channel_ref "$channel")"
  UNI_REF="$ref"
  [[ -n "$EMU_REF" ]] || EMU_REF="$ref"
  [[ -n "$INSTALL_UPDATE_REF" ]] || INSTALL_UPDATE_REF="$ref"
}

configure_installer_manifest() {
  IUL_PACKAGE_NAME="uni-launcher"
  IUL_COMMAND_NAME="uni"
  IUL_COMMAND_SOURCE="$SCRIPT_DIR/uni"
  IUL_MODULE_SOURCE_DIR="$MODULE_DIR"
  if [[ -f "$SCRIPT_DIR/completions/uni.bash" ]]; then
    IUL_COMPLETION_SOURCE="$SCRIPT_DIR/completions/uni.bash"
  elif [[ -f "$HOME/.local/share/bash-completion/completions/uni" ]]; then
    IUL_COMPLETION_SOURCE="$HOME/.local/share/bash-completion/completions/uni"
  else
    IUL_COMPLETION_SOURCE="/usr/local/share/bash-completion/completions/uni"
  fi
}

install_uni() {
  load_install_update_library
  configure_installer_manifest
  iul_install "$1"
}

update_uni() {
  load_install_update_library
  iul_apply_from_git update "$1" "$UNI_REPOSITORY" "$UNI_REF" \
    uni-launcher uni uni lib/uni completions/uni.bash
}

manage_launcher_package() {
  local action="$1" package="$2" system="$3"
  load_install_update_library
  case "$package" in
    emu)
      iul_apply_from_git "$action" "$system" "$EMU_REPOSITORY" "$EMU_REF" \
        emu-launcher emu emu lib/emu completions/emu.bash
      ;;
    installer)
      iul_apply_from_git "$action" "$system" "$INSTALL_UPDATE_REPOSITORY" "$INSTALL_UPDATE_REF" \
        install-update-launcher install-update-launcher install-update-launcher \
        lib/install-update-launcher ""
      ;;
    *) die "unknown launcher package: $package" 2 ;;
  esac
}

cleanup_installer_checkout() {
  [[ -z "$INSTALL_UPDATE_CHECKOUT" ]] || rm -rf "$INSTALL_UPDATE_CHECKOUT"
}
