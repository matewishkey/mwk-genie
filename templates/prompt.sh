# --- put the genie in the box ------------------------------------------------
# A prompt that says one thing: where you are.
#
# The default prompt on most machines opens with your username and the
# computer's name. Neither ever changes, so neither is ever worth reading, and
# they push the only useful part — the folder — off to the right.
#
# This shows the folder, and once a project is on GitHub, its branch and a `*`
# if there is work in it you have not saved:
#
#   ~/projects/holiday-photos (main*) $
#
# The `*` is the useful one. It is the answer to "have I saved?" without asking.

__mwk_git() {
  br=$(git branch --show-current 2>/dev/null) || return
  [ -n "$br" ] || return
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    printf ' (%s*)' "$br"
  else
    printf ' (%s)' "$br"
  fi
}

if [ -n "$ZSH_VERSION" ]; then
  setopt PROMPT_SUBST
  PROMPT='%F{cyan}%~%f%F{yellow}$(__mwk_git)%f $ '
else
  PS1='\[\e[36m\]\w\[\e[0m\]\[\e[33m\]$(__mwk_git)\[\e[0m\] $ '
fi
# -----------------------------------------------------------------------------
