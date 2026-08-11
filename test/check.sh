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
# Runs every category, then exits non-zero if anything failed.

set -uo pipefail
cd "$(dirname "$0")/.."

pass=0 fail=0 skipped=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail + 1)); }
# Counted separately on purpose: a check that never ran is not a check that
# passed, and a green tally that includes skips is a lie about coverage.
skip() { printf '  \033[33m–\033[0m %s\n' "$1"; skipped=$((skipped + 1)); }
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

# A rename breaks the two download URLs in SETUP.md, and those are the first
# thing a stranger runs. Derive the slug from the remote rather than trusting a
# hardcoded copy, so this tracks the rename instead of needing one.
slug=$(git config --get remote.origin.url \
  | sed -E 's#(git@github\.com:|https://github\.com/)##; s#\.git$##')
if [ -n "$slug" ]; then
  miss=""
  grep -qF "github.com/$slug.git" SETUP.md || miss="$miss clone-url"
  grep -qF "github.com/$slug/archive" SETUP.md || miss="$miss tarball-url"
  [ -z "$miss" ] \
    && ok "SETUP.md downloads from $slug (matches the remote)" \
    || bad "SETUP.md download URLs do not match the remote ($slug):$miss"
else
  skip "the download-URL check (no git remote)"
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
  for f in SETUP.md templates/howto.html .claude-plugin/marketplace.json; do
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

# The learning skill keeps ONE page forever, and the way it fails is by quietly
# making a second one. Three things have to survive every edit to that file.
L=plugin/skills/learning/SKILL.md

# 1. The title is the last way home when both stored copies are gone, so it has
#    to be written down here rather than left to whoever runs the command.
grep -qE '^ {4}What we learnt$' "$L" \
  && ok "learning: the artifact title is pinned in the skill" \
  || bad "learning: no pinned artifact title -- recovery-by-title cannot work if it drifts"

# 2. Finding the address is useless without passing it to the publish step. A
#    session that did not create the page makes a NEW one unless told which to
#    update, which is the whole failure mode wearing a success mask.
grep -qi 'handing the publish step that address' "$L" \
  && ok "learning: says to hand the stored address to the publish step" \
  || bad "learning: never says to pass the address when publishing -- it will create a second page"

# 3. Both stored copies, and the refusal to guess when they are gone.
for want in 'mwk-genie-learning.txt' '<!-- artifact:' 'Stop. Do not publish'; do
  grep -qF -- "$want" "$L" \
    && ok "learning: keeps '$want'" \
    || bad "learning: lost '$want' -- one of the three ways home is gone"
done

# --- the bookmark page -------------------------------------------------------
# templates/howto.html is the one artefact they keep, the only branded thing in
# the kit, and the only page here with a script on it. All three are reasons it
# gets checked rather than trusted.
head_ "The bookmark page"

# One python pass prints its own results and a machine-readable tally on the
# last line, so the counts fold into this script's.
tally=$(python3 - <<'PY_END'
import re, pathlib
h = pathlib.Path('templates/howto.html').read_text(encoding='utf-8')
res = []
def check(cond, msg): res.append((bool(cond), msg))

# Every command block needs exactly one copy button. A block without one is a
# line they must select by hand -- the thing this page exists to avoid. A
# button with no <pre> beside it throws on click.
blocks = re.findall(r'<div class="cmd">(.*?)</div>', h, re.S)
paired = [b for b in blocks if '<pre>' in b and 'class="copy"' in b]
check(blocks and len(paired) == len(blocks),
      f"every command block has a copy button ({len(paired)}/{len(blocks)})")
check(all(re.search(r'<pre>\s*\S', b) for b in blocks), "no command block is empty")

# The API is unavailable in more contexts than people expect, and a button that
# silently does nothing is worse than no button on a page written for a beginner.
check('navigator.clipboard' in h and 'execCommand' in h,
      "copy has a clipboard API path and an execCommand fallback")

# An artifact runs under a strict CSP: anything from another host is missing.
loaded = [u for u in re.findall(r'(?:src|href)="(https?://[^"]+)"', h)
          if re.match(r'.*\.(css|js|woff2?|png|jpg|svg)$', u)]
check(not loaded, "nothing is loaded from another host" + (f" (found {loaded})" if loaded else ""))

# Red is spent once. The design kit is explicit that a second red spend costs
# the first its effect, and a copy button is the obvious place to slip.
m = re.search(r'\.copy \{(.*?)\}', h, re.S)
check(m and 'var(--red' not in m.group(1), "the copy buttons are not red")

# A missing token means a colour got hardcoded and will not track the site.
for tok in ('--red', '--red-field', '--red-deep', '--paper', '--ink', '--mute', '--faint'):
    check(f'{tok}:' in h, f"token {tok} is defined")

check('prefers-color-scheme: dark' in h and '[data-theme="dark"]' in h,
      "dark theme covers prefers-color-scheme and an explicit data-theme")

for good, msg in res:
    print(("  \033[32m\u2713\033[0m " if good else "  \033[31m\u2717\033[0m ") + msg)
print(sum(1 for g, _ in res if g), sum(1 for g, _ in res if not g))
PY_END
)
printf '%s\n' "$tally" | sed '$d'
pass=$((pass + $(printf '%s' "$tally" | tail -1 | cut -d' ' -f1)))
fail=$((fail + $(printf '%s' "$tally" | tail -1 | cut -d' ' -f2)))

# The block must be the real logo file. Hand-building a red square is how the
# site ended up with three logos and no rule between them; this catches a drift
# back, and also catches the site redrawing the mark without us noticing.
live_svg=$(curl -sL --max-time 20 https://matewishkey.com/favicon.svg 2>/dev/null)
if [ -n "$live_svg" ]; then
  live_d=$(printf '%s' "$live_svg" | grep -o 'd="[^"]*"' | sort | tr -d '\n')
  page_d=$(grep -o 'd="[^"]*"' templates/howto.html | sort | tr -d '\n')
  { [ -n "$live_d" ] && [ "$live_d" = "$page_d" ]; } \
    && ok "the block is the real favicon.svg, unmodified" \
    || bad "the block does not match matewishkey.com/favicon.svg"
else
  skip "the block check (could not reach matewishkey.com)"
fi

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
# must give the other. That swap is the instruction we print in howto.html.
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

# The blocker this whole marker business exists for. Installing twice used to
# leave TWO `alias ccc=` pairs; the instruction on howto.html says to move the
# `#`, the person edits the first pair, and the second one -- still the
# skip-permissions one -- wins. They ask for the safe option and silently get
# the other. Simulate exactly that: append twice, swap the first pair, and
# check what the shell actually ends up with.
rc=$(mktemp)
python3 - "$rc" templates/ccc.sh <<'PY'
# Exactly what SETUP.md step 2 tells the agent to do: replace between the
# markers when they are present, append when they are not. Run it twice.
import sys
rcfile, block = sys.argv[1], sys.argv[2]
new = open(block).read()
o, c = '# >>> mwk-genie:ccc >>>', '# <<< mwk-genie:ccc <<<'
for _ in range(2):
    cur = open(rcfile).read()
    if o in cur and c in cur:
        head = cur[:cur.index(o)]
        tail = cur[cur.index(c) + len(c):]
        tail = tail.split('\n', 1)[1] if '\n' in tail else ''
        cur = head + new.lstrip('\n') + tail
    else:
        cur = cur + new
    open(rcfile, 'w').write(cur)
PY
n=$(grep -c "^alias ccc=\|^# alias ccc=" "$rc")
[ "$n" = 2 ] \
  && ok "installing twice the documented way leaves one alias pair, not two" \
  || bad "installing twice left $n alias lines (want 2: one live, one commented)"

# ...and then the person follows howto.html and moves the # on the first pair.
python3 - "$rc" <<'PY'
import sys
ls = open(sys.argv[1]).read().split('\n')
off = on = False
for i, l in enumerate(ls):
    if not off and l.startswith("alias ccc='claude --dangerously"):
        ls[i] = '# ' + l; off = True
    elif not on and l.startswith("# alias ccc='claude'"):
        ls[i] = l[2:]; on = True
open(sys.argv[1], 'w').write('\n'.join(ls))
PY
got=$(bash -c "source $rc; alias ccc" 2>/dev/null)
case "$got" in
  *dangerously*) bad "installed twice, moving the # leaves the skip-permissions alias live" ;;
  *claude*)      ok "installed twice, moving the # still gives the asks-every-time version" ;;
  *)             bad "twice-installed ccc.sh defines no alias (got: ${got:-nothing})" ;;
esac
rm -f "$rc"

# And if an agent ignores the markers and appends blindly anyway, the check
# SETUP.md mandates has to notice. This is the last line of defence.
blind=$(mktemp); cat templates/ccc.sh templates/ccc.sh > "$blind"
[ "$(grep -c '^alias ccc=' "$blind")" = 2 ] \
  && ok "a blind double-append is caught by SETUP.md's grep -c guard" \
  || bad "a blind double-append would slip past the grep -c guard in SETUP.md"
rm -f "$blind"

# Both templates are fenced by markers so SETUP.md can replace rather than
# append. Without them there is nothing to replace and the bug above returns.
for m in ccc prompt; do
  o=$(grep -c "^# >>> mwk-genie:$m >>>" "templates/$m.sh")
  c=$(grep -c "^# <<< mwk-genie:$m <<<" "templates/$m.sh")
  [ "$o" = 1 ] && [ "$c" = 1 ] \
    && ok "templates/$m.sh is fenced by its replace markers" \
    || bad "templates/$m.sh markers: $o opening, $c closing (want 1 and 1)"
  grep -qF "mwk-genie:$m" SETUP.md \
    && ok "SETUP.md tells the agent about the mwk-genie:$m markers" \
    || bad "SETUP.md never mentions the mwk-genie:$m markers, so it will append blindly"
done

# The installer puts claude in ~/.local/bin and touches no startup file, so
# without this `ccc` is command-not-found in any non-login shell.
grep -qF '.local/bin' templates/ccc.sh \
  && ok "ccc.sh puts ~/.local/bin on PATH" \
  || bad "ccc.sh does not add ~/.local/bin to PATH -- ccc will not resolve in a non-login shell"

n=$(env -i HOME=/nonexistent PATH=/usr/bin:/bin bash -c \
      ". $PWD/templates/ccc.sh; . $PWD/templates/ccc.sh; printf '%s' \"\$PATH\"" 2>/dev/null \
    | tr ':' '\n' | grep -c '^/nonexistent/.local/bin$')
[ "$n" = 1 ] \
  && ok "sourcing ccc.sh twice does not stack duplicate PATH entries" \
  || bad "ccc.sh put ~/.local/bin on PATH $n times after two sources (want 1)"

# A startup file with no trailing newline used to have its last line welded to
# our first, producing two errors at the top of every new terminal forever.
nl=$(mktemp)
printf 'export MWK_LAST_LINE=1' > "$nl"        # deliberately no trailing newline
cat templates/ccc.sh >> "$nl"
bash -c "source $nl" 2>/dev/null \
  && ok "appending to a file with no trailing newline still sources cleanly" \
  || bad "appending ccc.sh to a file with no trailing newline breaks it"
rm -f "$nl"

# prompt.sh runs inside somebody's startup file. An unset variable under set -u
# aborts everything below it.
bash -c "set -u; source $PWD/templates/prompt.sh" 2>/dev/null \
  && ok "prompt.sh survives set -u" \
  || bad "prompt.sh aborts under set -u -- the rest of their startup file stops running"

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

# Testing __mwk_git is not testing the prompt. Deleting `setopt PROMPT_SUBST`
# passes every check above while a real zsh window renders a literal
# "$(__mwk_git)" on every line -- on the platform rehearse.sh never touches.
# So render the actual prompt and look for the branch in it.
touch "$tmp/dirty"

zd=$(mktemp -d); cp templates/prompt.sh "$zd/.zshrc"
rendered=$(cd "$tmp" && HOME="$zd" ZDOTDIR="$zd" zsh -i -c 'print -rP "$PROMPT"' 2>/dev/null)
case "$rendered" in
  *'(main*)'*|*'(master*)'*) ok "zsh: the rendered prompt contains the branch and star" ;;
  *'__mwk_git'*) bad "zsh: prompt renders a literal \$(__mwk_git) -- PROMPT_SUBST is missing" ;;
  *) bad "zsh: rendered prompt has no branch in it (got: ${rendered:-nothing})" ;;
esac
rm -rf "$zd"

here=$PWD
rendered=$(cd "$tmp" && bash -c ". '$here/templates/prompt.sh'; printf '%s' \"\${PS1@P}\"" 2>/dev/null)
case "$rendered" in
  *'(main*)'*|*'(master*)'*) ok "bash: the rendered prompt contains the branch and star" ;;
  *'__mwk_git'*) bad "bash: prompt renders a literal \$(__mwk_git)" ;;
  *) bad "bash: rendered prompt has no branch in it (got: ${rendered:-nothing})" ;;
esac

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

# Both fences are rendered as reader-facing copy on matewishkey.com. That site
# fails its own build on an em dash in rendered text, but deliberately exempts
# <pre> -- which is exactly what these become. So the guard has to live here.
# Mate's call 2026-08-09: no long dashes in anything published. Prose outside
# the fence is GitHub-only and is not checked.
for f in prompts/install.md prompts/setup.md; do
  n=$(python3 - "$f" <<'PY'
import re, sys
b = re.search(r'^```\n(.*?)^```', open(sys.argv[1]).read(), re.S | re.M).group(1)
print(sum(b.count(d) for d in ('—', '–')))
PY
)
  [ "$n" = 0 ] \
    && ok "$f fence: no em or en dashes" \
    || bad "$f fence has $n em/en dash(es) -- they render on matewishkey.com"
done

# --- every URL handed to a stranger ------------------------------------------
# A 404 here is not a broken link, it is a beginner's first five minutes.
head_ "URLs"

# 200 is not enough. A URL that 301s still "works" — right up until somebody
# re-uses the old path, which is how /wishes/... and the repo rename both went.
# So the URL we ship has to be the one that answers, not one that forwards.
# Pass "redirects-ok" for a URL that legitimately does (a shortener, a CDN).
check_url() {
  read -r code final < <(curl -sL -o /dev/null \
    -w '%{http_code} %{url_effective}' --max-time 20 "$1" 2>/dev/null)
  if [ "$code" != "200" ]; then
    bad "$code  $1"
  elif [ "${2:-}" != "redirects-ok" ] && [ "$final" != "$1" ]; then
    bad "$code  $1 -> redirects to $final (ship the final one)"
  else
    ok "$code  $1"
  fi
}
check_url "https://github.com/matewishkey/mwk-genie"
check_url "https://raw.githubusercontent.com/matewishkey/mwk-genie/main/SETUP.md"
check_url "https://github.com/matewishkey/mwk-genie/archive/refs/heads/main.tar.gz" redirects-ok  # -> codeload CDN
check_url "https://matewishkey.com/"
# The canonical path. /wishes/... still 301s here, but a redirect is not a home:
# it holds until somebody re-uses the old path, exactly like the repo rename.
check_url "https://matewishkey.com/how-to/put-the-genie-in-the-box/"
# The branded how-to page reads its colours off these two.
check_url "https://matewishkey.com/design/"
check_url "https://matewishkey.com/media/"
# The point of the whole kit: the bookmark page and the end of setup send them here.
check_url "https://matewishkey.com/show/"
check_url "https://www.youtube.com/@matewishkey"
check_url "https://www.twitch.tv/matewishkey"
# Where we send them when something is wrong or costs money.
check_url "https://github.com/matewishkey/mwk-genie/issues/new/choose" redirects-ok  # -> login when signed out
check_url "https://github.com/anthropics/claude-code/issues"
check_url "https://claude.com/pricing"
# The installer everything downstream assumes exists.
check_url "https://claude.ai/install.sh" redirects-ok  # -> downloads.claude.ai; the stable name is the point
# macOS step one installs iTerm2 with Homebrew. Brew is for iTerm2 only -- the
# agent still installs itself, which rehearse.sh phase C asserts in a container.
check_url "https://brew.sh/"
check_url "https://iterm2.com/"

# The cask name is quoted in prompts/install.md. Homebrew's own API is the
# authority on whether that token still exists -- guessing it is how a beginner
# gets "No available formula" as their first command on a new Mac.
if grep -qF 'brew install --cask iterm2' prompts/install.md; then
  tok=$(curl -sL --max-time 20 https://formulae.brew.sh/api/cask/iterm2.json \
        | python3 -c 'import json,sys; print(json.load(sys.stdin).get("token",""))' 2>/dev/null)
  [ "$tok" = "iterm2" ] \
    && ok "homebrew cask 'iterm2' exists" \
    || bad "prompts/install.md installs cask 'iterm2' but the Homebrew API returned '${tok:-nothing}'"
else
  # Never let this vanish silently: reword the command and the check would
  # simply stop running, with no failure and no notice.
  skip "prompts/install.md no longer contains 'brew install --cask iterm2' -- cask check not run"
fi

# Ctrl+J is the universal newline and the only thing that works in Apple's
# Terminal. /terminal-setup does NOT set Shift+Enter up there, and saying it
# does sends the person who declined the install away believing it is fixed.
grep -qF 'Ctrl+J' SETUP.md \
  && ok "SETUP.md gives them Ctrl+J for a new line" \
  || bad "SETUP.md never mentions Ctrl+J, the one newline key that works everywhere"
grep -qF 'Ctrl+J' templates/howto.html \
  && ok "the bookmark page gives them Ctrl+J" \
  || bad "templates/howto.html never mentions Ctrl+J"
# It may only appear as the warning not to reach for it. Any other mention is
# the old wrong advice creeping back.
if ! grep -qF 'terminal-setup' SETUP.md; then
  ok "SETUP.md does not mention /terminal-setup"
elif [ "$(grep -cF 'terminal-setup' SETUP.md)" = 1 ] && grep -qF 'Do not offer' SETUP.md; then
  ok "SETUP.md mentions /terminal-setup only to warn the agent off it"
else
  bad "SETUP.md offers /terminal-setup as an Apple Terminal fix -- it does not do that"
fi

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -X POST \
  https://mcp.context7.com/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"mwk-check","version":"1"}}}' 2>/dev/null)
[ "$code" = "200" ] && ok "$code  context7 MCP endpoint" || bad "$code  context7 MCP endpoint"

# The Anthropic plugins SETUP.md installs have to exist in that catalogue.
# Derive the list FROM SETUP.md rather than hardcoding it: the old version
# grepped SETUP.md for a quoted "frontend-design" that is never written that
# way, so the condition was always false and the else always printed a pass --
# including for a plugin name that does not exist. A check that cannot fail is
# worse than no check, because it is counted in the total.
avail=$(curl -sL --max-time 20 \
  https://raw.githubusercontent.com/anthropics/claude-code/main/.claude-plugin/marketplace.json)
plugins=$(grep -oE 'claude plugin install [a-z0-9-]+@claude-code-plugins' SETUP.md \
          | sed 's/claude plugin install //; s/@claude-code-plugins//' | sort -u)
if [ -z "$plugins" ]; then
  bad "no 'claude plugin install <name>@claude-code-plugins' lines found in SETUP.md"
elif [ -z "$avail" ]; then
  skip "could not fetch the Anthropic marketplace"
else
  for p in $plugins; do
    echo "$avail" | grep -qF "\"$p\"" \
      && ok "$p exists in the Anthropic marketplace" \
      || bad "SETUP.md installs '$p' but it is not in the anthropics/claude-code marketplace"
  done
fi

# --- done --------------------------------------------------------------------
# Skips are reported, never folded into the pass count — the checks that skip
# are the ones that need the network, so a run with skips has not verified the
# things most likely to have drifted.
if [ "$skipped" -gt 0 ]; then
  printf '\n\033[1m%d passed, %d failed, %d skipped\033[0m\n' "$pass" "$fail" "$skipped"
  printf '\033[33mSkipped checks did not run — they are not passes.\033[0m\n'
else
  printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
fi
[ "$fail" -eq 0 ] || exit 1
