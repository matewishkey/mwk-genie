#!/usr/bin/env bash
# Walk the kit through a machine that has never seen it.
#
# A clean Ubuntu container, a normal non-root user, and deliberately no `git`
# and no `curl` to start with — because that is the machine SETUP.md warns
# about, and because "it works on the box I wrote it on" is not evidence.
#
#   bash test/rehearse.sh
#
# Three phases:
#   A  stage zero, against the PUBLISHED repo — both download paths
#   B  stage one, against YOUR WORKING TREE — the shell files, in a fresh shell
#   C  stage two, the plugin — real Claude Code, installed the way we tell them
#
# Phase A tests `main`, so it can pass while your uncommitted changes are
# broken; phase B is the one that tests what you are about to push.
#
# What this does NOT cover is in test/MANUAL.md. Read it.

set -uo pipefail
cd "$(dirname "$0")/.."
REPO=$PWD
IMAGE=ubuntu:24.04
NAME=mwk-rehearse-$$

pass=0 fail=0
ok()    { printf '  \033[32m✓\033[0m %s\n' "$1"; pass=$((pass + 1)); }
bad()   { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail + 1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }
# Run as the beginner, not as root. `bash -ic` with no TTY warns about job
# control on every call; that is docker, not us, so it does not reach asserts.
u()     { docker exec -u newbie -w /home/newbie "$NAME" bash -c "$1" 2>&1 \
            | grep -vE 'cannot set terminal process group|no job control in this shell'; }
root()  { docker exec "$NAME" bash -c "$1" >/dev/null 2>&1; }

command -v docker >/dev/null || { echo "docker is not installed"; exit 1; }
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

printf 'Starting a clean %s…\n' "$IMAGE"
docker run -d --name "$NAME" "$IMAGE" sleep 3600 >/dev/null || exit 1
root "useradd -m -s /bin/bash newbie"

# =============================================================================
head_ "A. Stage zero — getting the kit onto a bare machine (published main)"
# =============================================================================

# SETUP.md says: check before you run one, because a minimal image ships with
# neither guaranteed. If this ever starts passing, that warning has gone stale.
u 'command -v git' >/dev/null && bad "image already has git — the no-tools branch is untested" \
                              || ok "bare image has no git, as SETUP.md assumes"
u 'command -v curl' >/dev/null && bad "image already has curl" \
                               || ok "bare image has no curl, as SETUP.md assumes"

printf '  … installing curl (this is the one thing stage zero may need a password for)\n'
root "apt-get update -qq && apt-get install -y -qq curl ca-certificates"

# The tarball path, exactly as SETUP.md writes it.
u 'mkdir -p ~/projects && curl -sL https://github.com/matewishkey/mwk-genie/archive/refs/heads/main.tar.gz \
   | tar xz -C ~/projects && mv ~/projects/mwk-genie-main ~/projects/mwk-genie' >/dev/null
if [ "$(u 'test -f ~/projects/mwk-genie/SETUP.md && echo yes')" = yes ]; then
  ok "curl + tar puts the kit in ~/projects/mwk-genie"
else
  bad "curl + tar path failed"
fi
u 'rm -rf ~/projects/mwk-genie' >/dev/null

printf '  … installing git\n'
root "apt-get install -y -qq git"

u 'git clone -q https://github.com/matewishkey/mwk-genie.git ~/projects/mwk-genie' >/dev/null
if [ "$(u 'test -f ~/projects/mwk-genie/SETUP.md && echo yes')" = yes ]; then
  ok "git clone puts the kit in ~/projects/mwk-genie"
else
  bad "git clone path failed"
fi

# From here on, test what is about to be pushed — not what is already on main.
# Never run git commands against this copy: your changes are uncommitted, and a
# stray `stash` or `checkout` silently reverts the container to published main.
u 'rm -rf ~/projects/mwk-genie' >/dev/null
docker cp "$REPO/." "$NAME:/home/newbie/projects/mwk-genie" >/dev/null
root "chown -R newbie:newbie /home/newbie/projects"
# No python3 in a base Ubuntu image — that is the point of testing on one.
want=$(python3 -c 'import json;print(json.load(open("plugin/.claude-plugin/plugin.json"))["version"])')
got=$(u "grep -o '\"version\": *\"[^\"]*\"' /home/newbie/projects/mwk-genie/plugin/.claude-plugin/plugin.json \
         | head -1 | sed 's/.*\"\\([0-9][^\"]*\\)\"/\\1/'" | tr -d '\r')
[ "$want" = "$got" ] \
  && ok "swapped in your working tree (version $got, not published main)" \
  || bad "the container is running version '$got' but your tree is '$want' — the copy did not take"

# =============================================================================
head_ "B. Stage one — the shell files, in a genuinely fresh shell"
# =============================================================================

# A stub `claude` that just reports how it was called. This is the whole point:
# `ccc` existing is not the same as `ccc` starting the agent the right way, and
# the difference is invisible to a beginner. It is what failed on show 001.
u 'mkdir -p ~/.local/bin && printf "%s\n" "#!/bin/sh" "echo STUB-CLAUDE \$*" > ~/.local/bin/claude \
   && chmod +x ~/.local/bin/claude && echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc' >/dev/null

u 'cat ~/projects/mwk-genie/templates/ccc.sh    >> ~/.bashrc
   cat ~/projects/mwk-genie/templates/prompt.sh >> ~/.bashrc' >/dev/null
ok "appended ccc.sh and prompt.sh to ~/.bashrc"

# A new terminal window is an interactive shell reading .bashrc. Nothing else
# counts — the whole failure mode is a shell that has not re-read that file.
out=$(u 'bash -ic ccc' | tr -d '\r')
case "$out" in
  *"STUB-CLAUDE --dangerously-skip-permissions"*)
    ok "fresh shell: ccc starts the agent with --dangerously-skip-permissions" ;;
  *STUB-CLAUDE*)
    bad "fresh shell: ccc ran but without the flag (got: $out)" ;;
  *)
    bad "fresh shell: ccc did not run at all (got: ${out:-nothing})" ;;
esac

# The swap we tell them about in howto.md has to actually work.
u "sed -i \"s|^alias ccc=|# alias ccc=|; s|^# alias ccc='claude'$|alias ccc='claude'|\" ~/.bashrc" >/dev/null
out=$(u 'bash -ic ccc' | tr -d '\r')
case "$out" in
  *dangerously*) bad "after moving the #, ccc still skips permissions" ;;
  *STUB-CLAUDE*) ok "after moving the #, ccc asks every time (got: $out)" ;;
  *)             bad "after moving the #, ccc did not run (got: ${out:-nothing})" ;;
esac
# Put it back the way it ships.
u "sed -i \"s|^alias ccc='claude'$|# alias ccc='claude'|; s|^# alias ccc='claude --dangerously|alias ccc='claude --dangerously|\" ~/.bashrc" >/dev/null

# The prompt: folder, branch, and the star that answers "have I saved?".
# On a throwaway project, not the kit — see the warning above.
u 'git config --global user.email t@example.com; git config --global user.name Tester
   mkdir -p ~/projects/demo && cd ~/projects/demo && git init -q && git commit -q --allow-empty -m first' >/dev/null

clean=$(u 'bash -ic "cd ~/projects/demo && __mwk_git"' | tr -d '\r')
dirty=$(u 'touch ~/projects/demo/notes.txt; bash -ic "cd ~/projects/demo && __mwk_git"' | tr -d '\r')
outside=$(u 'bash -ic "cd /tmp && __mwk_git"' | tr -d '\r')

case "$clean" in
  *\*\))     bad "fresh shell: a saved project shows a star it should not ('$clean')" ;;
  *"("*")"*) ok  "fresh shell: saved project shows '$clean'" ;;
  *)         bad "fresh shell: saved project showed '${clean:-nothing}'" ;;
esac
case "$dirty" in
  *\*\)) ok  "fresh shell: unsaved work shows '$dirty'" ;;
  *)     bad "fresh shell: unsaved work showed '${dirty:-nothing}' — the star is missing" ;;
esac
[ -z "$outside" ] && ok "fresh shell: silent outside a project" \
                  || bad "fresh shell: printed '$outside' outside a project"

# =============================================================================
head_ "C. Stage two — the plugin, with real Claude Code"
# =============================================================================

u 'rm -f ~/.local/bin/claude' >/dev/null   # the stub has done its job
printf '  … installing Claude Code the way SETUP.md assumes: its own installer,\n'
printf '    no Homebrew, no apt, no npm\n'
u 'curl -fsSL https://claude.ai/install.sh | bash' >/dev/null

if [ "$(u 'test -x ~/.local/bin/claude && echo yes')" = yes ]; then
  ok "Claude Code installed itself, no package manager involved"
else
  bad "the official installer did not produce ~/.local/bin/claude — skipping the rest of C"
  printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"; [ "$fail" -eq 0 ] || exit 1; exit 0
fi

C='export PATH=$HOME/.local/bin:$PATH;'
u "$C claude plugin marketplace add ~/projects/mwk-genie" >/dev/null
out=$(u "$C claude plugin install mwk-genie@matewishkey")
case "$out" in
  *"Successfully installed"*) ok "installs off their own disk, no login needed" ;;
  *) bad "plugin install failed: $out" ;;
esac

out=$(u "$C claude plugin list")
case "$out" in
  *"Version: $want"*) ok "installed version is $want — it read the disk, not GitHub" ;;
  *) bad "expected version $want in plugin list; got: $out" ;;
esac

n_skills=$(find plugin/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
details=$(u "$C claude plugin details mwk-genie@matewishkey")
missing=""
for d in plugin/skills/*/; do
  s=$(basename "$d")
  case "$details" in *"$s"*) ;; *) missing="$missing $s" ;; esac
done
[ -z "$missing" ] \
  && ok "all $n_skills skills resolve in the installed plugin" \
  || bad "installed plugin is missing skills:$missing"

# Step 10 warns: merge the model key, do not overwrite, because step 9 already
# wrote to this file. Prove both halves — that the plugin really did write
# there, and that adding "model" on top leaves it installed. Merge on the host;
# the container has no python3, which is exactly the situation being tested.
settings=$(docker exec -u newbie "$NAME" cat /home/newbie/.claude/settings.json 2>/dev/null)
if [ -z "$settings" ]; then
  bad "no ~/.claude/settings.json after installing the plugin"
else
  keys=$(printf '%s' "$settings" | python3 -c 'import json,sys;print(",".join(json.load(sys.stdin)))')
  ok "the plugin wrote to settings.json (keys: $keys) — step 10's warning has something to protect"

  printf '%s' "$settings" \
    | python3 -c 'import json,sys;d=json.load(sys.stdin);d["model"]="sonnet";print(json.dumps(d,indent=2))' \
    | docker exec -i -u newbie "$NAME" tee /home/newbie/.claude/settings.json >/dev/null

  still=$(u "$C claude plugin list")
  has_model=$(u "grep -c '\"model\"' ~/.claude/settings.json" | tr -d '\r')
  if [ "$has_model" -ge 1 ] && [ "${still#*mwk-genie}" != "$still" ]; then
    ok "merging \"model\": \"sonnet\" in leaves the plugin installed"
  else
    bad "after adding \"model\" the plugin is gone — merging is not optional"
  fi
fi

# =============================================================================
printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
