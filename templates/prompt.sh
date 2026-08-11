
# >>> mwk-genie:prompt >>> ------------------------------------------------------
# Everything between these two marker lines belongs to the kit. Running the
# setup again replaces this block rather than adding a second copy.
#
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
  local br st
  # GIT_OPTIONAL_LOCKS=0 keeps these from writing to .git on every prompt.
  br=$(GIT_OPTIONAL_LOCKS=0 git branch --show-current 2>/dev/null) || return
  [ -n "$br" ] || return
  # zsh re-reads % as a prompt escape, so a branch name containing one would
  # colour or corrupt the prompt. Doubling it prints a literal %.
  [ -n "${ZSH_VERSION:-}" ] && br=${br//\%/%%}
  st=$(GIT_OPTIONAL_LOCKS=0 git status --porcelain 2>/dev/null)
  if [ -n "$st" ]; then
    printf ' (%s*)' "$br"
  else
    printf ' (%s)' "$br"
  fi
}

# ${ZSH_VERSION:-} rather than $ZSH_VERSION: an unset variable under `set -u`
# would abort the rest of the startup file, and everything below this would
# silently stop running.
if [ -n "${ZSH_VERSION:-}" ]; then
  setopt PROMPT_SUBST
  PROMPT='%F{cyan}%~%f%F{yellow}$(__mwk_git)%f $ '
else
  PS1='\[\e[36m\]\w\[\e[0m\]\[\e[33m\]$(__mwk_git)\[\e[0m\] $ '
fi
# <<< mwk-genie:prompt <<< ------------------------------------------------------
