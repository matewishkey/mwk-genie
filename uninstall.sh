#!/bin/sh
# Take it all back off, so it can go straight back on.
#
#   sh ~/projects/mwk-genie/uninstall.sh          ask about anything that is theirs
#   sh ~/projects/mwk-genie/uninstall.sh --all    take everything, still confirming once
#   sh ~/projects/mwk-genie/uninstall.sh --dry-run   say what would go, touch nothing
#
# WHY THIS EXISTS: the kit is meant to be installed on a stranger's machine, and anything
# you can put on someone's computer you should be able to take off it. It is also the only
# way to test the installer honestly — a second install onto a machine that still has the
# first one is not the thing a new person experiences.
#
# WHAT IT WILL NOT DO: silently delete anything of theirs. Their keys and their work are
# MOVED TO THE TRASH, not erased, and it says so before and after. A password store that
# vanishes on a typo would be the worst thing this kit could do.
set -eu

DRY=0; ALL=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --all)     ALL=1 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'unknown option: %s\n' "$a" >&2; exit 2 ;;
  esac
done

# ── colour ────────────────────────────────────────────────────────────────────────────
# Mate Wish Key red is #e2342b. Truecolor where the terminal says it can, the nearest
# xterm-256 red otherwise, and nothing at all when the output is not a terminal — a log
# full of escape codes helps nobody.
if [ -t 1 ]; then
  case "${COLORTERM:-}" in
    truecolor|24bit) RED=$(printf '\033[38;2;226;52;43m') ;;
    *)               RED=$(printf '\033[38;5;203m') ;;
  esac
  B=$(printf '\033[1m'); DIM=$(printf '\033[2m'); GRN=$(printf '\033[32m'); R=$(printf '\033[0m')
else
  RED=''; B=''; DIM=''; GRN=''; R=''
fi
say()  { printf '%s\n' "$*"; }
head_() { printf '\n%s%s%s\n' "$B$RED" "$1" "$R"; }
item() { printf '  %s%s%s  %s%s%s\n' "$GRN" "$1" "$R" "$DIM" "$2" "$R"; }

# ── trash, not rm ─────────────────────────────────────────────────────────────────────
# macOS has ~/.Trash. Linux desktops use the freedesktop spec, which wants a .trashinfo
# beside the file or the desktop trash shows it as an orphan.
if [ "$(uname -s)" = Darwin ]; then TRASH="$HOME/.Trash"; INFO=""
else TRASH="$HOME/.local/share/Trash/files"; INFO="$HOME/.local/share/Trash/info"; fi

trash_it() {
  [ -e "$1" ] || return 0
  if [ "$DRY" = 1 ]; then item "would move to trash" "$1"; return 0; fi
  mkdir -p "$TRASH"; [ -n "$INFO" ] && mkdir -p "$INFO"
  base=$(basename "$1"); dest="$TRASH/$base"
  # Never clobber something already in the trash — that would destroy the very thing the
  # trash is for.
  [ -e "$dest" ] && dest="$TRASH/$base.$(date +%Y%m%d-%H%M%S)"
  if [ -n "$INFO" ]; then
    printf '[Trash Info]\nPath=%s\nDeletionDate=%s\n' "$1" "$(date +%Y-%m-%dT%H:%M:%S)" \
      > "$INFO/$(basename "$dest").trashinfo" 2>/dev/null || true
  fi
  mv "$1" "$dest"
  item "moved to trash" "$1"
}
wipe() {
  [ -e "$1" ] || return 0
  if [ "$DRY" = 1 ]; then item "would delete" "$1"; return 0; fi
  rm -rf "$1"; item "deleted" "$1"
}
ask() {
  [ "$ALL" = 1 ] && return 0
  [ -t 0 ] || return 1          # no keyboard means no consent. Keep it.
  printf '  %s%s%s [y/N] ' "$B" "$1" "$R"
  IFS= read -r a || return 1
  case "$a" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

printf '\n%s%sTaking Mate Wish Key back off this computer%s\n' "$B" "$RED" "$R"
[ "$DRY" = 1 ] && say "${DIM}Dry run — nothing will be touched.$R"
say "${DIM}Anything of yours goes to the trash, not the bin. You can put it back.$R"

head_ "The parts that are just plumbing"
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] || continue
  grep -q 'mwk-shell.sh' "$rc" 2>/dev/null || continue
  if [ "$DRY" = 1 ]; then item "would unhook" "$rc"; else
    tmp="$rc.mwk.$$"
    grep -v 'mwk-shell.sh' "$rc" > "$tmp" && mv "$tmp" "$rc"
    item "unhooked" "$rc"
  fi
done
wipe "$HOME/.mwk-shell.sh"
wipe "$HOME/bin/mwk"
for s in "$HOME"/.claude/skills/mwk-*; do [ -e "$s" ] && wipe "$s"; done
wipe "$HOME/.config/chezmoi"
wipe "$HOME/.local/share/chezmoi"

head_ "Things that might be yours"

if [ -d "$HOME/.mwk" ]; then
  printf '\n  %s%sYour keys live in ~/.mwk%s\n' "$B" "$RED" "$R"
  say "  ${DIM}Everything you saved with 'mwk add' is in there, locked with your master"
  say "  password. It goes to the trash rather than being erased, so you can put it back —"
  say "  but the trash does get emptied, and nobody can rebuild it for you.$R"
  if ask "Take your keys off this computer?"; then trash_it "$HOME/.mwk"
  else item "kept" "$HOME/.mwk"; fi
fi

if [ -d "$HOME/mwk" ]; then
  if ask "Remove your page and anything saved beside it (~/mwk)?"; then trash_it "$HOME/mwk"
  else item "kept" "$HOME/mwk"; fi
fi

if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  say "  ${DIM}~/.claude/CLAUDE.md is the file you were told you could edit.$R"
  if ask "Remove it?"; then trash_it "$HOME/.claude/CLAUDE.md"
  else item "kept" "$HOME/.claude/CLAUDE.md"; fi
fi

if [ -d "$HOME/Applications/iTerm.app" ]; then
  if ask "Remove iTerm2?"; then trash_it "$HOME/Applications/iTerm.app"
  else item "kept" "$HOME/Applications/iTerm.app"; fi
fi

if [ -d "$HOME/.local/share/mise" ]; then
  say "  ${DIM}mise is the tool that installed the other tools. If you had it before this"
  say "  kit, or another project uses it, keep it.$R"
  if ask "Remove mise and the tools it fetched?"; then
    wipe "$HOME/.local/share/mise"; wipe "$HOME/.local/bin/mise"; wipe "$HOME/.cache/mise"
  else item "kept" "mise"; fi
fi

head_ "The kit itself"
trash_it "$HOME/projects/mwk-genie"

printf '\n%s%sDone.%s\n' "$B" "$GRN" "$R"
say "${DIM}Claude Code itself was left alone — you are still signed in.$R"
say "${DIM}Open a NEW terminal window: 'ccc' and 'mwk' should both be gone from it.$R"
say "${DIM}Anything moved to the trash is in $TRASH$R"
printf '\n'
