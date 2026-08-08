#!/usr/bin/env bash
# Everything about this kit that a script can check without a browser or a login.
#
# Run it before every push. It is fast, it needs no Docker, and it catches the
# two things that have actually broken in front of a real person: a shell file
# that does not work in a fresh window, and a command in SETUP.md that quotes a
# name nothing answers to.
#
#   bash test/check.sh
#
# Exits non-zero on the first category that fails, after running them all.

set -uo pipefail
cd "$(dirname "$0")/.."

pass=0 fail=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail + 1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# --- the plugin manifests ----------------------------------------------------
head_ "Plugin manifests"

if claude plugin validate . >/dev/null 2>&1; then
  ok "claude plugin validate"
else
  bad "claude plugin validate — run it directly to see why"
fi

mp_name=$(python3 -c 'import json;print(json.load(open(".claude-plugin/marketplace.json"))["name"])')
pl_name=$(python3 -c 'import json;print(json.load(open(".claude-plugin/marketplace.json"))["plugins"][0]["name"])')
mp_ver=$(python3 -c 'import json;print(json.load(open(".claude-plugin/marketplace.json"))["plugins"][0]["version"])')
pl_ver=$(python3 -c 'import json;print(json.load(open("plugin/.claude-plugin/plugin.json"))["version"])')
pl_own=$(python3 -c 'import json;print(json.load(open("plugin/.claude-plugin/plugin.json"))["name"])')

[ "$mp_ver" = "$pl_ver" ] \
  && ok "versions match ($mp_ver)" \
  || bad "version mismatch: marketplace $mp_ver, plugin $pl_ver"

[ "$pl_name" = "$pl_own" ] \
  && ok "plugin named the same in both manifests ($pl_name)" \
  || bad "plugin name mismatch: marketplace says $pl_name, plugin.json says $pl_own"

# validate does NOT check that SETUP.md quotes these correctly. It broke once.
if grep -qF "claude plugin install ${pl_name}@${mp_name}" SETUP.md; then
  ok "SETUP.md installs ${pl_name}@${mp_name}"
else
  bad "SETUP.md does not contain: claude plugin install ${pl_name}@${mp_name}"
fi

if grep -qF "claude plugin marketplace add ~/projects/${PWD##*/}" SETUP.md; then
  ok "SETUP.md adds the marketplace from ~/projects/${PWD##*/}"
else
  bad "SETUP.md marketplace path does not match this directory name (${PWD##*/})"
fi

# --- the skills --------------------------------------------------------------
head_ "Skills"

for d in plugin/skills/*/; do
  name=$(basename "$d")
  f="$d/SKILL.md"
  if [ ! -f "$f" ]; then bad "$name has no SKILL.md"; continue; fi
  fm_name=$(sed -n '/^---$/,/^---$/p' "$f" | sed -n 's/^name: *//p' | head -1)
  fm_desc=$(sed -n '/^---$/,/^---$/p' "$f" | sed -n 's/^description: *//p' | head -1)
  if [ "$fm_name" != "$name" ]; then
    bad "$name: frontmatter name is '$fm_name', folder is '$name'"
  elif [ -z "$fm_desc" ]; then
    bad "$name: no description in frontmatter"
  else
    ok "$name"
  fi
done

# Add a skill and forget to document it and nobody finds out. Every command has
# to be named in the two places a person reads — the setup sheet and the page
# they bookmark — and in the marketplace description, which is the one that
# lists them individually. (plugin.json's description is the short blurb shown
# on install; it is deliberately not an inventory.)
for d in plugin/skills/*/; do
  name=$(basename "$d")
  missing=""
  for f in SETUP.md templates/howto.md .claude-plugin/marketplace.json; do
    grep -qF -- "/mwk-genie:$name" "$f" || missing="$missing $f"
  done
  [ -z "$missing" ] \
    && ok "/mwk-genie:$name is documented everywhere" \
    || bad "/mwk-genie:$name is missing from:$missing"
done

# The count is also written out in words, and drifts silently when a skill is
# added. Only lines that are talking about *these* commands — "three commands
# they should actually know" is cd/ls/mkdir and is none of our business.
n_skills=$(find plugin/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
words=(zero one two three four five six seven eight nine ten)
count_drift=0
for i in "${!words[@]}"; do
  [ "$i" = "$n_skills" ] && continue
  hits=$(grep -rniE "\b${words[$i]} (commands|things it does)\b" \
      --exclude-dir=.git --exclude-dir=test . \
    | grep -iE "mwk-genie|in every folder|not developers" || true)
  if [ -n "$hits" ]; then
    bad "there are $n_skills commands, but this says ${words[$i]}:
$hits"
    count_drift=1
  fi
done
[ "$count_drift" = 0 ] && ok "the written-out count matches ($n_skills commands)"

# --- the shell templates -----------------------------------------------------
# These land in a stranger's ~/.zshrc or ~/.bashrc. A syntax error here breaks
# every terminal they open, on a machine they do not know how to fix. And
# passing a syntax check is not the same as working: prompt.sh branches on
# $ZSH_VERSION, so it has to be sourced in both.
head_ "Shell templates"

for f in templates/ccc.sh templates/prompt.sh; do
  bash -n "$f" 2>/dev/null && ok "bash -n $f" || bad "bash -n $f"
  zsh  -n "$f" 2>/dev/null && ok "zsh -n $f"  || bad "zsh -n $f"
done

# ccc.sh ships two alias lines; exactly one must be live, and swapping the `#`
# must give the other. That swap is the instruction we print in howto.md.
live=$(grep -c '^alias ccc=' templates/ccc.sh)
comm=$(grep -c '^# alias ccc=' templates/ccc.sh)
[ "$live" = 1 ] && [ "$comm" = 1 ] \
  && ok "ccc.sh has one live alias and one commented alternative" \
  || bad "ccc.sh should have exactly 1 live and 1 commented alias (got $live live, $comm commented)"

for sh in bash zsh; do
  got=$($sh -c 'source templates/ccc.sh; alias ccc' 2>/dev/null)
  case "$got" in
    *--dangerously-skip-permissions*) ok "$sh: ccc is the get-on-with-it one" ;;
    *) bad "$sh: sourcing ccc.sh did not define the expected alias (got: ${got:-nothing})" ;;
  esac
done

swapped=$(mktemp)
sed 's|^alias ccc=|# alias ccc=|; s|^# alias ccc=.claude.$|alias ccc='"'"'claude'"'"'|' \
  templates/ccc.sh > "$swapped"
for sh in bash zsh; do
  got=$($sh -c "source $swapped; alias ccc" 2>/dev/null)
  case "$got" in
    *dangerously*) bad "$sh: swapping the # left the skip-permissions alias live" ;;
    *claude*)      ok "$sh: moving the # gives the asks-every-time version" ;;
    *)             bad "$sh: swapped ccc.sh defines no alias (got: ${got:-nothing})" ;;
  esac
done
rm -f "$swapped"

# prompt.sh must print ` (branch)`, ` (branch*)` when dirty, and nothing at all
# outside a repo. The `*` is the thing the whole prompt exists for.
tmp=$(mktemp -d)
git -C "$tmp" init -q 2>/dev/null
git -C "$tmp" commit -q --allow-empty -m init 2>/dev/null
for sh in bash zsh; do
  clean=$($sh -c "source '$PWD/templates/prompt.sh'; cd '$tmp' && __mwk_git" 2>/dev/null)
  touch "$tmp/dirty"
  dirty=$($sh -c "source '$PWD/templates/prompt.sh'; cd '$tmp' && __mwk_git" 2>/dev/null)
  rm -f "$tmp/dirty"
  outside=$($sh -c "source '$PWD/templates/prompt.sh'; cd / && __mwk_git" 2>/dev/null)

  [ -n "$clean" ] && [ "${clean%\*)}" = "$clean" ] \
    && ok "$sh: clean repo shows '$clean'" \
    || bad "$sh: clean repo showed '${clean:-nothing}'"
  case "$dirty" in
    *\*\)) ok "$sh: unsaved work shows '$dirty'" ;;
    *)     bad "$sh: unsaved work showed '${dirty:-nothing}' — the star is missing" ;;
  esac
  [ -z "$outside" ] \
    && ok "$sh: silent outside a repo" \
    || bad "$sh: printed '$outside' outside a repo"
done
rm -rf "$tmp"

# --- the prompt people paste -------------------------------------------------
# matewishkey.com publishes the first fenced block of prompts/setup.md and its
# build asserts this. A long line here breaks somebody else's build, and pastes
# as soup in the terminal of the person least able to tell why.
head_ "Pasted prompt width"

read -r n_lines maxlen over <<<"$(python3 - <<'PY'
import re
b = re.search(r'```[^\n]*\n(.*?)```', open('prompts/setup.md').read(), re.S).group(1)
ls = b.rstrip('\n').split('\n')
print(len(ls), max(len(l) for l in ls), sum(1 for l in ls if len(l) > 60))
PY
)"
[ "$over" = 0 ] \
  && ok "prompts/setup.md fence: $n_lines lines, longest $maxlen (limit 60)" \
  || bad "prompts/setup.md fence has $over line(s) over 60 columns (longest $maxlen)"

# --- every URL handed to a stranger ------------------------------------------
# A 404 here is not a broken link, it is a beginner's first five minutes.
head_ "URLs"

check_url() {
  code=$(curl -sL -o /dev/null -w '%{http_code}' --max-time 20 "$1" 2>/dev/null)
  [ "$code" = "200" ] && ok "$code  $1" || bad "$code  $1"
}
check_url "https://github.com/matewishkey/mwk-genie"
check_url "https://raw.githubusercontent.com/matewishkey/mwk-genie/main/SETUP.md"
check_url "https://github.com/matewishkey/mwk-genie/archive/refs/heads/main.tar.gz"
check_url "https://matewishkey.com/wishes/put-the-genie-in-the-box"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -X POST \
  https://mcp.context7.com/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"mwk-check","version":"1"}}}' 2>/dev/null)
[ "$code" = "200" ] && ok "$code  context7 MCP endpoint" || bad "$code  context7 MCP endpoint"

# The three Anthropic plugins SETUP.md installs have to exist in that catalogue.
avail=$(curl -sL --max-time 20 \
  https://raw.githubusercontent.com/anthropics/claude-code/main/.claude-plugin/marketplace.json)
for p in frontend-design feature-dev security-guidance; do
  if grep -qF "\"$p\"" SETUP.md && ! echo "$avail" | grep -qF "\"$p\""; then
    bad "SETUP.md installs '$p' but it is not in the anthropics/claude-code marketplace"
  else
    ok "$p exists in the Anthropic marketplace"
  fi
done

# --- done --------------------------------------------------------------------
printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
