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

INSTALL_UPDATE_LIBRARY="$(find_install_update_library)" || \
  die "install-update-launcher est requis. Gardez son depot a cote de uni-launcher ou installez-le." 1
source "$INSTALL_UPDATE_LIBRARY"

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
  configure_installer_manifest
  iul_install "$1"
}

update_uni() {
  configure_installer_manifest
  iul_update "$1"
}
