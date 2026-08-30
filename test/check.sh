#!/usr/bin/env bash
# Fast checks, no Docker. `bash test/check.sh` from the repo root.
#
# THE RULE THIS FILE EXISTS UNDER: when a check goes green, ask what would have to be true
# for it to go red. If you cannot construct that case, the check is decoration. Three of
# v1's green ticks were counting nothing — a grep for a quoted string that never appears, a
# glob that matched no directories, a `$()` that yielded "" on a traceback and compared
# equal to "". All three had been green for months. Prefer a check that can fail loudly to
# one that reads thoroughly.
#
# ⚠ WRITTEN, NOT YET RUN. This replaces a 659-line suite for v1 that could not pass on v2.
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0
ok()   { printf '  \033[32m✓\033[0m %s\n'   "$1"; pass=$((pass+1)); }
no()   { printf '  \033[31m✗\033[0m %s\n'   "$1"; printf '      %s\n' "${2:-}"; fail=$((fail+1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }
is()   { if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "expected [$3], got [$2]"; fi; }

head_ "Nothing points at a file that no longer exists"
for dead in SETUP.md templates/ccc.sh templates/prompt.sh templates/howto.html \
            .claude-plugin/marketplace.json plugin/.claude-plugin/plugin.json; do
  [ -e "$dead" ] && { no "$dead is deleted" "it is still here"; continue; }
  hits=$(grep -rn --exclude-dir=.git --exclude-dir=docs -F "$dead" . 2>/dev/null \
         | grep -v '^./CLAUDE.md:' | grep -v '^./test/check.sh:' | wc -l)
  is "nothing references $dead" "$hits" "0"
done
stale=$(grep -rn --exclude-dir=.git '/mwk-genie:' dot_claude/ prompts/ README.md 2>/dev/null | wc -l)
is "no /mwk-genie: command names survive" "$stale" "0"

head_ "The two prompts — they are published to a live public page"
for f in prompts/install.md prompts/setup.md; do
  n=$(grep -c '^```' "$f")
  is "$f has exactly one fenced block" "$n" "2"
  first=$(grep -n '^```' "$f" | head -1 | cut -d: -f1)
  body=$(sed -n "1,$((first-1))p" "$f")
  # The site publishes the FIRST fence. A second fence above the prompt publishes the wrong
  # thing, silently, on somebody else's website.
  case "$body" in *'```'*) no "$f: no fence before the published one" "found one";; *) ok "$f: the published fence is the first";; esac
  bytes=$(awk -v n="$first" 'NR>n && /^```/{exit} NR>n{c+=length($0)+1} END{print c+0}' "$f")
  [ "$bytes" -gt 200 ] && ok "$f: fence is non-empty ($bytes bytes)" \
    || no "$f: fence looks empty" "$bytes bytes — an empty fence throws on their build"
done

head_ "Tools are pinned, and the lock matches"
latest=$(grep -c '"latest"' mise.toml)
is "no tool floats on \"latest\"" "$latest" "0"
for t in chezmoi sops age miniserve jq; do
  v=$(grep -oE "aqua:[^\"]*/$t\" *= *\"[^\"]+\"" mise.toml | grep -oE '"[0-9][^"]*"' | tr -d '"')
  if [ -z "$v" ]; then no "$t is pinned in mise.toml" "not found"; continue; fi
  grep -qF "\"$v\"" mise.lock && ok "$t $v is in mise.lock" || no "$t $v is in mise.lock" "absent"
done

head_ "The shell file — both branches, both shells"
for mode in fast careful; do
  r=$(sed "s/^ccc_mode:.*/ccc_mode: $mode/" .chezmoidata.yaml > /tmp/cd.$$.yaml; \
      chezmoi execute-template --source . < dot_mwk-shell.sh.tmpl 2>/dev/null)
  [ -n "$r" ] || { no "renders for ccc_mode=$mode" "empty"; continue; }
done
rm -f /tmp/cd.$$.yaml
rendered=$(chezmoi execute-template --source . < dot_mwk-shell.sh.tmpl 2>/dev/null)
live=$(printf '%s\n' "$rendered" | grep -c '^alias ccc=')
is "exactly one LIVE ccc alias (the other is commented)" "$live" "1"
commented=$(printf '%s\n' "$rendered" | grep -c '^# alias ccc=')
is "the other alias is present, commented — the escape hatch" "$commented" "1"
for sh in bash zsh; do
  if command -v $sh >/dev/null 2>&1; then
    printf '%s\n' "$rendered" | $sh -n - 2>/dev/null \
      && ok "it is valid $sh" || no "it is valid $sh" "syntax error — this lands in a stranger's shell"
  fi
done
for d in '$HOME/.local/bin' '$HOME/bin' 'mise/shims'; do
  case "$rendered" in *"$d"*) ok "PATH includes $d";; *) no "PATH includes $d" "missing — mwk or claude will be command not found";; esac
done

head_ "The store — the boundaries that are load-bearing"
bash -n bin/executable_mwk && ok "mwk is valid sh" || no "mwk is valid sh" "syntax error"
n=$(grep -c 'require_tty' bin/executable_mwk)
[ "$n" -ge 4 ] && ok "init/add/rekey are behind require_tty ($n uses)" \
  || no "init/add/rekey are behind require_tty" "only $n uses"
v=$(grep -c '^[^#]*--value' bin/executable_mwk)
is "there is no --value flag (argv, ps and history)" "$v" "0"
for guard in 'refusing: the page directory is inside the store' \
             'refusing: the store is inside the page directory' \
             '\-i 127.0.0.1' '\-P '; do
  grep -q -- "$guard" bin/executable_mwk && ok "site guard: ${guard:0:44}" \
    || no "site guard: ${guard:0:44}" "missing — miniserve binds 0.0.0.0 and follows symlinks by default"
done
grep -q 'unset SOPS_AGE_KEY' bin/executable_mwk && ok "the master key is unset before the wrapped command runs" \
  || no "the master key is unset before the wrapped command runs" "it would be inherited"

head_ "Skills"
for d in dot_claude/skills/*/; do
  name=$(basename "$d")
  fm=$(awk 'NR>1 && /^---$/{exit} /^name:/{print $2}' "$d/SKILL.md")
  is "$name: frontmatter name matches its directory" "$fm" "$name"
done
grep -q 'mwk/site/learnt.html' dot_claude/skills/mwk-learning/SKILL.md \
  && ok "mwk-learning writes to the local page, not an artifact" \
  || no "mwk-learning writes to the local page" "still publishing somewhere"
grep -q 'artifact:' dot_claude/skills/mwk-learning/SKILL.md \
  && no "mwk-learning has no artifact machinery left" "found 'artifact:'" \
  || ok "mwk-learning has no artifact machinery left"

head_ "The page they keep"
site=mwk/site/index.html
grep -q 'e2342b' "$site" && ok "the block carries the brand red" || no "the block carries the brand red" "missing"
reds=$(grep -o 'e2342b' "$site" | wc -l)
is "red is spent once, on the block" "$reds" "1"
grep -q 'queue.json' "$site" && ok "the page reads queue.json" || no "the page reads queue.json" "missing"
grep -q 'cmd_queue' bin/executable_mwk && ok "…and mwk writes it" || no "…and mwk writes it" "the page would have no producer"
if command -v curl >/dev/null 2>&1; then
  live_logo=$(curl -fsS --max-time 10 https://matewishkey.com/favicon.svg 2>/dev/null | grep -oE 'd="M0 100[^"]*"' | head -1)
  page_logo=$(grep -oE 'd="M0 100[^"]*"' "$site" | head -1)
  if [ -z "$live_logo" ]; then no "logo matches the live favicon" "could not fetch it — not the same as matching"
  else is "logo matches the live favicon exactly" "$page_logo" "$live_logo"; fi
fi

head_ "Every URL handed to a stranger"
if command -v curl >/dev/null 2>&1; then
  urls=$(grep -rhoE 'https?://[A-Za-z0-9._~:/?#@!$&()*+,;=%-]+' \
          README.md prompts/ mwk/site/ dot_claude/ install.sh mise.toml 2>/dev/null \
        | sed 's/[.,)]*$//' | sort -u | grep -vE 'localhost|127\.0\.0\.1|example\.')
  for u in $urls; do
    code=$(curl -s -o /dev/null -m 15 -w '%{http_code}' -L "$u" 2>/dev/null)
    case "$code" in
      200|204) ok "$code  $u" ;;
      000)     no "unreachable  $u" "no response — a 404 here is a beginner's first five minutes" ;;
      *)       no "$code  $u" "not a 200" ;;
    esac
  done
else
  no "URL check" "curl is missing"
fi

printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
