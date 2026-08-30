#!/bin/sh
# The whole setup, as one command they paste once:
#
#   curl -fsSL https://raw.githubusercontent.com/matewishkey/mwk-genie/main/install.sh | sh
#
# WHY A SCRIPT AND NOT AN AGENT WORKING THROUGH A DOCUMENT (mate's call, 2026-08-30):
# v1 asked Claude to read SETUP.md and carry out ~30 steps by interpreting prose. Every
# documented near-miss in this repo came out of that — a block appended instead of replaced,
# two `alias ccc=` pairs with the dangerous one silently winning. A script does the same work
# the same way every time, and it frees the agent for the thing they actually came for.
#
# POSIX sh on purpose: it runs before anything is installed, including bash on a minimal image.
set -eu

REPO="https://github.com/matewishkey/mwk-genie"
# Which branch to install. Defaults to main; the rehearsal sets it to test a branch for real
# rather than pre-placing the kit, which would be the test arranging its own precondition.
REF="${MWK_REF:-main}"
KIT="$HOME/projects/mwk-genie"
BIN="$HOME/.local/bin"

# Mate Wish Key red is #e2342b. Truecolor when the terminal says it can, the nearest
# xterm-256 red otherwise, and nothing at all when this is piped somewhere — the first
# thing a person sees should not be a screenful of escape codes.
if [ -t 1 ]; then
  case "${COLORTERM:-}" in
    truecolor|24bit) RED=$(printf '\033[38;2;226;52;43m') ;;
    *)               RED=$(printf '\033[38;5;203m') ;;
  esac
  B=$(printf '\033[1m'); DIM=$(printf '\033[2m'); GRN=$(printf '\033[32m'); R=$(printf '\033[0m')
else
  RED=''; B=''; DIM=''; GRN=''; R=''
fi

say()  { printf '\n%s%s%s%s\n' "$B" "$RED" "$*" "$R"; }
step() { printf '  %s%s%s\n' "$DIM" "$*" "$R"; }
have() { command -v "$1" >/dev/null 2>&1; }

# `command -v git` is TRUE on every Mac even with no developer tools, because /usr/bin/git
# is Apple's xcode-select shim — verified 2026-08-30: /usr/bin/git and /usr/bin/clang are
# the SAME INODE (1152921500312571562, 78 hardlinks) and the binary links libxcselect.
# Running it pops a GUI dialog and exits non-zero, and this script is `set -eu`, so the
# whole install would die at step 1. Ask whether git WORKS, not whether a file exists.
have_git() {
  command -v git >/dev/null 2>&1 || return 1
  if [ "$(uname -s)" = Darwin ] && ! xcode-select -p >/dev/null 2>&1; then return 1; fi
  return 0
}

case "$(uname -s)" in
  Darwin|Linux) ;;
  *) printf 'This needs macOS or Linux. On Windows, open your Ubuntu window and run it there.\n' >&2; exit 1 ;;
esac

say "1/5  Getting the kit"
mkdir -p "$HOME/projects"
if [ -d "$KIT/.git" ] && have_git; then
  step "already here — updating"; git -C "$KIT" pull --ff-only >/dev/null 2>&1 || true
elif have_git; then
  step "cloning"; git clone --quiet --branch "$REF" "$REPO.git" "$KIT"
else
  # A Mac with no developer tools has a /usr/bin/git that only offers to install Xcode.
  # curl is always real there, so the tarball is the kinder path. Safe to re-run.
  step "downloading (no git needed)"
  mkdir -p "$KIT"
  curl -fsSL "$REPO/archive/refs/heads/$REF.tar.gz" | tar xz --strip-components=1 -C "$KIT"
fi

say "2/5  Installing mise (this is the only tool that installs tools)"
if have mise; then step "already installed"; else curl -fsSL https://mise.run | sh >/dev/null; fi
PATH="$BIN:$HOME/.local/share/mise/shims:$PATH"; export PATH

say "3/5  Installing chezmoi, sops, age and miniserve"
step "from $KIT/mise.toml — same versions on every machine"
( cd "$KIT" && mise install --yes >/dev/null 2>&1 ) || ( cd "$KIT" && mise install --yes )

say "4/5  Installing Claude Code"
if have claude; then step "already installed"; else curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1 || true; fi

say "5/5  Setting up your computer"
step "two questions, then everything else is automatic"
# Extra arguments are handed to chezmoi. That is how an unattended run supplies the two
# answers:  ... | sh -s -- --promptChoice ccc_mode=fast --promptBool admin=true
#
# ⚠ chezmoi's prompts need a TTY (measured: "could not open a new TTY: open /dev/tty").
# So THIS SCRIPT CANNOT BE RUN BY AN AGENT either — same boundary as `mwk add`. That is
# the design, not a limitation: the person runs the script, the agent does the work after.
mise exec -C "$KIT" -- chezmoi init --apply --source "$KIT" "$@"

printf '\n  %s────────────────────────────────────────────────────────────%s\n' "$DIM" "$R"
printf '   %s%sDone.%s One thing left, and it has to be you:\n\n' "$B" "$GRN" "$R"
printf '     Close this window and open a new one.\n'
printf '     Then type:   %s%sccc%s\n\n' "$B" "$RED" "$R"
printf '   %sA terminal only reads its settings when it starts, so your\n' "$DIM"
printf '   new shortcut does not exist in this window yet.%s\n' "$R"
printf '  %s────────────────────────────────────────────────────────────%s\n\n' "$DIM" "$R"
