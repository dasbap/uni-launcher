_uni() {
  local cur prev runners games
  COMPREPLY=(); cur="${COMP_WORDS[COMP_CWORD]}"; prev="${COMP_WORDS[COMP_CWORD-1]}"
  runners="$(sed -n '/^[^#[:space:]][^=]*=/s/=.*//p' "${XDG_CONFIG_HOME:-$HOME/.config}/uni/runners" 2>/dev/null)"
  games="$(sed -n '/^[^#[:space:]][^=]*=/s/=.*//p' "${XDG_CONFIG_HOME:-$HOME/.config}/uni/games" 2>/dev/null | sed '/\.__/d')"
  case "$prev" in
    --add-runner|--remove-runner|--link) COMPREPLY=( $(compgen -W "$runners" -- "$cur") ); return ;;
    --add-game|--add-emu-game|--set-emu) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac
  COMPREPLY=( $(compgen -W "--help --list --foreground --dry-run --verbose --add-runner --remove-runner --add-game --add-emu-game --link --unlink --remove-game --set-emu launchers doctor --install --update --system --channel --ref stable prerelease development --installed --missing --current --updates --with-installer --with-emu --all --clear-config $runners $games" -- "$cur") )
}
complete -F _uni uni
