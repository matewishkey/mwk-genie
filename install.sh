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

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
step() { printf '  %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

case "$(uname -s)" in
  Darwin|Linux) ;;
  *) printf 'This needs macOS or Linux. On Windows, open your Ubuntu window and run it there.\n' >&2; exit 1 ;;
esac

say "1/5  Getting the kit"
mkdir -p "$HOME/projects"
if [ -d "$KIT/.git" ] && have git; then
  step "already here — updating"; git -C "$KIT" pull --ff-only >/dev/null 2>&1 || true
elif have git; then
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
mise exec -C "$KIT" -- chezmoi init --apply --source "$KIT"

cat <<'DONE'

  ────────────────────────────────────────────────────────────
   Done. One thing left, and it has to be you:

     Close this window and open a new one.
     Then type:   ccc

   A terminal only reads its settings when it starts, so your
   new shortcut does not exist in this window yet.
  ────────────────────────────────────────────────────────────

DONE
