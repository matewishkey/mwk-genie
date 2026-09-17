#!/usr/bin/env bash
# Fast checks, no Docker. `bash test/check.sh` from the repo root.
#
# THE RULE THIS FILE EXISTS UNDER: when a check goes green, ask what would have to be true
# for it to go red. If you cannot construct that case, the check is decoration. Three of
# v1's green ticks were counting nothing — a grep for a quoted string that never appears, a
# glob that matched no directories, a `$()` that yielded "" on a traceback and compared
# equal to "". All three had been green for months. Prefer a check that can fail loudly to
# one that reads thoroughly.
set -uo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0
ok()   { printf '  \033[32m✓\033[0m %s\n'   "$1"; pass=$((pass+1)); }
no()   { printf '  \033[31m✗\033[0m %s\n'   "$1"; printf '      %s\n' "${2:-}"; fail=$((fail+1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }
is()   { if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "expected [$3], got [$2]"; fi; }

head_ "Nothing points at a file that no longer exists"
for dead in SETUP.md templates/ccc.sh templates/prompt.sh templates/howto.html \
            .claude-plugin/marketplace.json plugin/.claude-plugin/plugin.json \
            mwk/site/index.html mwk/site/password.html bin/executable_mwk-debug debug-worker; do
  [ -e "$dead" ] && { no "$dead is deleted" "it is still here"; continue; }
  # A COMMENT about a deleted file is history, not a dead pointer — install.sh explains why
  # it exists by naming what it replaced, and that sentence should survive. Only count lines
  # that reference it as a live thing.
  hits=$(grep -rn --exclude-dir=.git --exclude-dir=docs -F "$dead" . 2>/dev/null \
         | grep -v '^./CLAUDE.md:' | grep -v '^./test/check.sh:' \
         | grep -vE ':[0-9]+:[[:space:]]*(#|//|<!--|\*)' | wc -l)
  is "nothing references $dead" "$hits" "0"
done
stale=$(grep -rn --exclude-dir=.git '/mwk-genie:' dot_claude/ prompts/ README.md 2>/dev/null | wc -l)
is "no /mwk-genie: command names survive" "$stale" "0"
# The commands that were cut on 2026-09-17. A doc still telling someone to type one of
# these is a beginner's first "command not found" — count live mentions in what ships.
for gone in 'mwk init' 'mwk list' 'mwk needs' 'mwk lock' 'mwk rekey' 'mwk site' 'mwk serve' \
            'mwk port' 'mwk queue' 'mwk files' 'mwk uninstall' 'mwk-debug'; do
  hits=$(grep -rn --exclude-dir=.git -F "$gone" README.md prompts/ dot_claude/ site-templates/ \
                  bin/ install.sh uninstall.sh dot_mwk-shell.sh.tmpl 2>/dev/null \
         | grep -vE ':[0-9]+:[[:space:]]*#' | wc -l)
  is "nothing still offers '$gone'" "$hits" "0"
done

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
# The read-before-you-run checklist names the hosts install.sh may fetch from. If the
# script fetches from one the list does not name, the guardrail fires on its own installer
# — and a guardrail that cries wolf the first time is ignored the second.
for host in $(grep -oE 'https://[a-zA-Z0-9.-]+' install.sh | sed 's|https://||' | sort -u); do
  grep -q "$host" prompts/setup.md && ok "setup.md's host list names $host" \
    || no "setup.md's host list names $host" "install.sh fetches from it and the checklist would flag it"
done

head_ "Tools are pinned, and the lock matches"
# Anchor on the assignment, not the file: the comment above it says the word "latest".
# A check that can never go green is how people learn to ignore the suite.
latest=$(grep -cE '^"aqua:[^"]+" *= *"latest"' mise.toml)
is "no tool floats on \"latest\"" "$latest" "0"
for t in chezmoi sops age miniserve jq cli; do
  v=$(grep -oE "aqua:[^\"]*/$t\" *= *\"[^\"]+\"" mise.toml | grep -oE '"[0-9][^"]*"' | tr -d '"')
  if [ -z "$v" ]; then no "$t is pinned in mise.toml" "not found"; continue; fi
  grep -qF "\"$v\"" mise.lock && ok "$t $v is in mise.lock" || no "$t $v is in mise.lock" "absent"
done
# The COUNT is written as a word in three documents, and it drifted twice in one day when a
# tool left and came back (an external sweep caught "five" against six). Derive it from
# mise.toml and assert every prose copy — the number is not a fact any document may hold alone.
ntools=$(grep -cE '^"aqua:' mise.toml)
case "$ntools" in 4) w=four;; 5) w=five;; 6) w=six;; 7) w=seven;; 8) w=eight;; *) w="$ntools";; esac
grep -qi "\b$w pinned tools" prompts/setup.md && ok "setup.md says '$w pinned tools' ($ntools in mise.toml)" \
  || no "setup.md says '$w pinned tools'" "mise.toml has $ntools; the prompt says something else"
grep -qi "^\*\*\`mise\` is already here and it owns the tools.\*\* ${w^} of them" dot_claude/create_CLAUDE.md \
  || grep -qi "${w^} of them are pinned" dot_claude/create_CLAUDE.md \
  && ok "create_CLAUDE.md says '${w^} of them' ($ntools)" \
  || no "create_CLAUDE.md says '${w^} of them'" "mise.toml has $ntools; the agent's rules say something else"
grep -qE "→ $ntools pinned tools" CLAUDE.md && ok "CLAUDE.md's one-pass says '$ntools pinned tools'" \
  || no "CLAUDE.md's one-pass says '$ntools pinned tools'" "it says something else"

head_ "The shell file, both shells — and no ccc anywhere"
rendered=$(chezmoi execute-template --source . < dot_mwk-shell.sh.tmpl 2>/dev/null)
[ -n "$rendered" ] && ok "the shell file renders" || no "the shell file renders" "empty"
# ccc is gone (2026-09-17): how Claude asks is permissions.defaultMode in settings, one
# home. An alias would be a second home, and two homes is how v1 got two definitions.
is "no ccc alias in the shell file" "$(printf '%s\n' "$rendered" | grep -c '^alias ccc')" "0"
ccc_docs=$(grep -rn --exclude-dir=.git -w 'ccc' README.md prompts/ dot_claude/ site-templates/ mwk-work/ install.sh uninstall.sh 2>/dev/null \
           | grep -vE ':[0-9]+:[[:space:]]*#' | wc -l)
is "no document still tells them to type ccc" "$ccc_docs" "0"

head_ "Their page — the server over ~/mwk-work"
serve=$(printf '%s\n' "$rendered" | grep -E '^\s*\( nohup miniserve ' )
[ -n "$serve" ] && ok "the shell file starts miniserve" || no "the shell file starts miniserve" "no start line — the bookmark answers nothing"
for flag in '-i 127.0.0.1' '-p 29200' ' -P ' '--readme' '"$HOME/mwk-work"'; do
  printf '%s' "$serve" | grep -qF -- "$flag" && ok "…with $flag" \
    || no "…with $flag" "miniserve binds 0.0.0.0 and follows symlinks by default"
done
printf '%s\n' "$rendered" | grep -q 'pgrep -x miniserve' && ok "…guarded by pgrep -x (never -f)" \
  || no "the start is guarded by pgrep -x" "-f matches its own command line and starts one per shell"
printf '%s\n' "$rendered" | grep -qE 'miniserve .* -q ' && no "no -q on miniserve" "-q is a QR code in 0.35.0, not quiet" \
  || ok "no -q (it means QR code, not quiet — checked --help)"
grep -q 'pkill -x miniserve' uninstall.sh && ok "uninstall stops it" || no "uninstall stops it" "a server would outlive the kit"

head_ "settings.json — opus, auto mode, the bar — merged, never replaced"
sh -n dot_claude/modify_settings.json && ok "modify_settings.json is valid sh" || no "modify_settings.json is valid sh" "syntax error"
if command -v jq >/dev/null 2>&1; then
  out=$(printf '{"enabledPlugins":{"x":true}}' | sh dot_claude/modify_settings.json)
  is "theirs survives: enabledPlugins"     "$(printf '%s' "$out" | jq -r '.enabledPlugins.x')" "true"
  is "ours lands: model opus"              "$(printf '%s' "$out" | jq -r '.model')" "opus"
  is "ours lands: permissions.defaultMode auto" "$(printf '%s' "$out" | jq -r '.permissions.defaultMode')" "auto"
  is "ours lands: statusLine → ~/.claude/statusline.sh" "$(printf '%s' "$out" | jq -r '.statusLine.command')" "~/.claude/statusline.sh"
  # The escape hatch: a value THEY set is never overwritten. This is what makes auto survivable.
  out2=$(printf '{"permissions":{"defaultMode":"default"},"model":"sonnet"}' | sh dot_claude/modify_settings.json)
  is "their defaultMode wins over ours"    "$(printf '%s' "$out2" | jq -r '.permissions.defaultMode')" "default"
  is "their model wins over ours"          "$(printf '%s' "$out2" | jq -r '.model')" "sonnet"
else
  no "settings merge was exercised (SKIPPED)" "no jq — this did not run, it is not a pass"
fi
sh -n dot_claude/executable_statusline.sh && ok "statusline.sh is valid sh" || no "statusline.sh is valid sh" "syntax error"
if command -v jq >/dev/null 2>&1; then
  bar=$(printf '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"%s/projects/x"},"context_window":{"used_percentage":34.6}}' "$HOME" \
        | HOME="$HOME" sh dot_claude/executable_statusline.sh)
  is "the bar reads model · folder · %% full" "$bar" "Opus · ~/projects/x · 34% full"
  bar0=$(printf '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/a"},"context_window":{}}' | sh dot_claude/executable_statusline.sh)
  is "…and a null percentage (before the first reply) is 0, not an error" "$bar0" "Opus · /a · 0% full"
  printf '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/a"},"context_window":{"used_percentage":81}}' \
    | sh dot_claude/executable_statusline.sh | grep -q $'\033\[38;5;203m' && ok "…and goes red past 70%" || no "the bar goes red past 70%" "no red escape at 81%"
fi
for sh in bash zsh; do
  if command -v $sh >/dev/null 2>&1; then
    printf '%s\n' "$rendered" | $sh -n - 2>/dev/null \
      && ok "it is valid $sh" || no "it is valid $sh" "syntax error — this lands in a stranger's shell"
  fi
done
for d in '$HOME/.local/bin' '$HOME/bin' 'mise/shims'; do
  case "$rendered" in *"$d"*) ok "PATH includes $d";; *) no "PATH includes $d" "missing — mwk or claude will be command not found";; esac
done

head_ "mwk — three commands, and the boundaries that are load-bearing"
bash -n bin/executable_mwk && ok "mwk is valid bash" || no "mwk is valid bash" "syntax error"
cmds=$(sed -n '/^case "\${1:-}" in/,/^esac/p' bin/executable_mwk | grep -oE '^  [a-z]+\)' | tr -d ' )' | tr '\n' ' ')
is "the dispatcher has exactly add, run, update" "$cmds" "add run update "
usage_n=$(bash bin/executable_mwk </dev/null 2>/dev/null | grep -c '^  mwk ')
is "…and usage lists exactly those three" "$usage_n" "3"
n=$(grep -c 'require_tty' bin/executable_mwk)
[ "$n" -ge 2 ] && ok "add is behind require_tty ($n uses)" || no "add is behind require_tty" "only $n uses"
# The help text names the flag in order to say it does not exist. Look at the arg parser.
v=$(grep -cE '^\s+(--value|-v)\)' bin/executable_mwk)
is "there is no --value flag (argv, ps and history)" "$v" "0"
grep -q '^export SOPS_AGE_KEY_FILE="\$KEY"' bin/executable_mwk \
  && ok "the key path is set explicitly, never inherited" \
  || no "the key path is set explicitly" "an ambient SOPS_AGE_KEY_FILE would point every decrypt at someone else's key"
grep -q -- '--config "\$STORE/.sops.yaml"' bin/executable_mwk \
  && ok "encryption names its .sops.yaml (sops searches from cwd, and cwd is the project)" \
  || no "encryption names its .sops.yaml" "run from inside a project, sops would find no rules"
grep -q -- '--filename-override "\$1"' bin/executable_mwk \
  && ok "…and overrides the filename, so the no-catch-all rule matches stdin" \
  || no "encryption overrides the filename" "stdin matches no rule and the write fails"
grep -q 'but the key that opens them is not' bin/executable_mwk \
  && ok "a store with no key refuses to mint a new one (the new-computer case)" \
  || no "a store with no key refuses to mint a new one" "a fresh key would lock them out of their own repo, silently"

# ── the add-eats-the-store class ──────────────────────────────────────────────────────
# Three separate mistakes had to line up for `mwk add` to replace the whole store with one
# key, and each is asserted on its own so a regression names itself.
add_body=$(sed -n '/^cmd_add()/,/^}/p' bin/executable_mwk)
printf '%s\n' "$add_body" | grep -q 'old=\$(sops_d "\$f") || die' \
  && ok "a failed read stops cmd_add" || no "a failed read stops cmd_add" "this is the bug that ate the store"
printf '%s\n' "$add_body" | grep -q 'now=\$(sops_d "\$f")' \
  && ok "cmd_add reads its own result back" || no "cmd_add reads back" "the one file with no reset deserves a read-back"
printf '%s\n' "$add_body" | grep -q 'mv "\$f.prev" "\$f"' \
  && ok "…and restores the previous ciphertext if anything is missing" || no "cmd_add restores on loss" "missing"

# THE REAL THING. Against a real scratch store, in a clean environment, through a pty —
# because `add` refuses without one. Confirmed red against the pre-fix binary on
# 2026-08-30; kept red-capable on the plain-key store by the negative case at the end.
if command -v sops >/dev/null 2>&1 && command -v age-keygen >/dev/null 2>&1 \
   && command -v script >/dev/null 2>&1 && script -qec true /dev/null >/dev/null 2>&1; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  cp bin/executable_mwk "$T/mwk"; chmod +x "$T/mwk"
  # env -i: this box's own shell exports SOPS_AGE_KEY_FILE, and that contaminated the first
  # round of store research. Nothing here may reach the real home or the real key.
  # `env` execs BINARIES — a shell function after it is "No such file", silently, which is
  # exactly how this block's first run reported "no store was made" against a store that was.
  # So the pty (script) is inside the env, not a function around it.
  #
  # And the tools must be REAL binaries, not mise shims: a shim looks up trust and versions
  # under $HOME, and $HOME here is a scratch dir where nothing is trusted and nothing is
  # installed — so every shim exits 1 with a mise error, and this block went red on code
  # that was fine. `mise which` gives the installed binary; the fallback is PATH with the
  # shims stripped (this box's fleet install). Neither touches the real home.
  tooldirs=""
  for t in sops age-keygen; do
    b=$(mise which "$t" 2>/dev/null || true)
    [ -n "$b" ] && tooldirs="$tooldirs$(dirname "$b"):"
  done
  noshim=$(printf '%s' "$PATH" | tr ':' '\n' | grep -v 'mise/shims' | paste -sd:)
  clean() { env -i HOME="$T" PATH="$tooldirs$noshim" TERM=dumb MWK_STORE="$T/keys" MWK_KEY="$T/key.txt" \
                   GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t "$@"; }
  cadd()  { clean script -qec "$T/mwk add $*" /dev/null; }
  names() { clean env SOPS_AGE_KEY_FILE="$T/key.txt" sops -d --input-type dotenv --output-type dotenv "$T/keys/keys.enc.env" 2>/dev/null \
            | grep -oE '^[A-Z]+' | sort -u | tr '\n' ' '; }
  printf 'value-a\n' | cadd ALPHA >/dev/null 2>&1
  if [ -s "$T/key.txt" ] && [ -f "$T/keys/.sops.yaml" ]; then
    ok "the first add makes the key and the store"
    is "…the key is 600" "$(stat -c %a "$T/key.txt" 2>/dev/null || stat -f %Lp "$T/key.txt")" "600"
    grep -q 'AGE-SECRET' "$T/keys/.sops.yaml" && no ".sops.yaml holds only the public key" "a SECRET line is in it" \
      || ok ".sops.yaml holds only the public key"
    printf 'value-b\n' | cadd BETA >/dev/null 2>&1
    is "adding a second key keeps the first" "$(names)" "ALPHA BETA "
    grep -q 'value-' "$T/keys/keys.enc.env" && no "the store file is ciphertext" "a plaintext value is in it" \
      || ok "the store file is ciphertext"
    c=$(git -C "$T/keys" log --oneline 2>/dev/null | wc -l)
    [ "$c" -ge 2 ] && ok "each add is a commit in the store ($c)" || no "each add commits" "$c commits"
    # Negative: the key goes missing (new computer). add must refuse, and change nothing.
    mv "$T/key.txt" "$T/key.bak"
    printf 'value-c\n' | cadd GAMMA >/dev/null 2>&1; rc=$?
    # And the scope that was removed must stay removed: a second argument is a usage error.
    printf 'value-d\n' | cadd DELTA global >/dev/null 2>&1 && no "a second argument to add is refused" "it accepted 'global' — the per-project scope is back" \
      || ok "a second argument to add is refused (no per-project scope)"
    mv "$T/key.bak" "$T/key.txt"
    [ "$rc" != 0 ] && ok "no key → add refuses (exit $rc)" || no "no key → add refuses" "it exited 0"
    is "…and the store is exactly as it was" "$(names)" "ALPHA BETA "
    [ -s "$T/key.txt" ] && ok "…and no new key was minted over the missing one" \
      || no "no new key minted" "a fresh key here locks them out of their own repo"
  else
    no "the first add makes the store (nothing below it ran)" "no key or no .sops.yaml was written"
  fi
else
  no "the store's behaviour was tested for real (SKIPPED)" \
     "needs sops, age-keygen and a working script(1) — this did not run, and that is not a pass"
fi

head_ "Only the right things reach a stranger's home directory"
# .chezmoiignore is an ALLOW-list and its patterns match TARGET names, not source names —
# get that wrong and it places NOTHING while looking correct. Assert both directions.
managed=$(chezmoi managed --source . 2>/dev/null)
for want in .claude/CLAUDE.md .claude/settings.json .claude/statusline.sh .claude/skills/mwk-save/SKILL.md \
            .claude/skills/mwk-tasks/SKILL.md .claude/skills/mwk-onboard/SKILL.md .mwk-shell.sh bin/mwk \
            mwk-work/README.md; do
  printf '%s\n' "$managed" | grep -qx "$want" && ok "placed: $want" || no "placed: $want" "MISSING"
done
# The howto is placed ONCE and never overwritten — ours on day one, theirs after. That is
# the create_ prefix, and nothing else: a plain file would revert their edits every apply.
[ -f mwk-work/create_README.md ] && ok "the howto is a create_ (write-once) file" \
  || no "the howto is a create_ file" "a managed file would overwrite what they changed"
grep -q 'bookmark' mwk-work/create_README.md && ok "…and it knows it is the page they bookmark" \
  || no "the howto knows it is the served front page" "it reads as a file, not as http://127.0.0.1:29200/"
grep -q 'mwk-work' dot_claude/skills/mwk-learn/SKILL.md && ! grep -q 'What I have learnt' dot_claude/skills/mwk-learn/SKILL.md \
  && ok "mwk-learn writes its log elsewhere and never into the howto" || no "mwk-learn stays out of mwk-work" "it would write over the front page"
n=$(grep -c 'matewishkey.com/show' mwk-work/create_README.md README.md | awk -F: '{s+=$2} END{print s}')
is "the show is mentioned exactly twice across what a person reads (howto + README)" "$n" "2"
for never in uninstall.sh README.md CLAUDE.md install.sh mise.toml mise.lock \
             test prompts docs site-templates mwk/ bin/mwk-debug projects; do
  printf '%s\n' "$managed" | grep -q "^$never" \
    && no "never placed: $never" "it is being copied into their home" || ok "never placed: $never"
done

head_ "Nothing guest-facing assumes our machines"
for term in td-sops 'work\.l' devproxy '192\.168' dotfiles-cz dokku healthchecks; do
  n=$(grep -rniI "$term" dot_claude/ bin/ prompts/ 2>/dev/null | wc -l)
  is "no reference to $term" "$n" "0"
done

head_ "It can be taken back off"
sh -n uninstall.sh && ok "uninstall.sh is valid sh" || no "uninstall.sh is valid sh" "syntax error"
grep -q 'trash_it "$HOME/.config/sops/age/keys.txt"' uninstall.sh \
  && ok "the key is TRASHED, never rm -rf'd" \
  || no "the key is trashed, never rm -rf'd" "the one file that opens their store must survive a typo"
grep -q 'projects/keys' uninstall.sh && ! grep -qE '(trash_it|wipe) "\$HOME/projects/keys"' uninstall.sh \
  && ok "~/projects/keys is left alone — it is theirs, like any project" \
  || no "~/projects/keys is left alone" "uninstall must not touch their repo"
grep -q '\[ -t 0 \] || return 1' uninstall.sh \
  && ok "no keyboard means no consent — it does not assume yes" \
  || no "no keyboard means no consent" "an unattended run could delete their key"

head_ "The starter websites"
for f in site-templates/one-page/index.html site-templates/pages/index.html \
         site-templates/pages/work.html site-templates/pages/about.html; do
  [ -f "$f" ] && ok "$f exists" || no "$f exists" "missing"
  grep -q 'href="mwk.css"' "$f" && ok "$(basename $(dirname "$f"))/$(basename "$f") loads the stylesheet beside it" \
    || no "$f loads mwk.css" "a template that renders unstyled is worse than none"
done
for d in one-page pages; do
  [ -f "site-templates/$d/mwk.css" ] && ok "$d ships its own copy of mwk.css" \
    || no "$d ships mwk.css" "copying the folder would give an unstyled site"
done
# Each template must carry the credit, and it must be inside a comment. Putting our name
# on a stranger's site by default is the thing the README promises we do not do.
for f in site-templates/*/*.html; do
  n=$(grep -c 'matewishkey' "$f" || true)
  is "$(basename $(dirname "$f"))/$(basename "$f") carries the credit" "$n" "1"
  if command -v perl >/dev/null 2>&1; then
    bare=$(perl -0777 -pe 's/<!--.*?-->//gs' "$f" | grep -c 'matewishkey' || true)
    is "…and it is commented out, not live" "$bare" "0"
  else
    no "…and it is commented out (SKIPPED)" "no perl — this did not run, it is not a pass"
  fi
done
for d in one-page pages; do
  if cmp -s site-templates/mwk.css "site-templates/$d/mwk.css"; then ok "$d/mwk.css matches the master"
  else no "$d/mwk.css matches the master" "the copies have drifted"; fi
done
grep -q 'site-templates' dot_claude/skills/mwk-new/SKILL.md \
  && ok "/mwk-new knows the templates exist" || no "/mwk-new knows the templates exist" "nothing would ever reach for them"
for want in 'input/' 'archive/' '.gitignore'; do
  grep -q -- "$want" dot_claude/skills/mwk-new/SKILL.md && ok "/mwk-new builds $want" \
    || no "/mwk-new builds $want" "the house rule in create_CLAUDE.md promises it"
done
grep -q 'site-templates/report/index.html' dot_claude/create_CLAUDE.md \
  && ok "the page rule points at the report template" || no "the page rule points at the report template" "the agent would write pages from nothing"
grep -q 'mwk-work/<project>/<YYYY-MM-DD_slug>' dot_claude/create_CLAUDE.md \
  && ok "…and at ~/mwk-work/<project>/<date_slug>/ — work.l's layout" || no "the page rule names the layout" "pages would land anywhere"
grep -q 'curl -sf -o /dev/null http://127.0.0.1:29200/' dot_claude/create_CLAUDE.md \
  && ok "…and checks the link answers before handing it over" || no "the agent checks the link first" "a dead link is the page's whole failure mode"
grep -q '<link' site-templates/report/index.html \
  && no "the report template is self-contained" "it loads an external file — an artifact cannot" \
  || ok "the report template is self-contained (no <link>)"

head_ "Skills"
for d in dot_claude/skills/*/; do
  name=$(basename "$d")
  fm=$(awk 'NR>1 && /^---$/{exit} /^name:/{print $2}' "$d/SKILL.md")
  is "$name: frontmatter name matches its directory" "$fm" "$name"
done
grep -q 'projects/learning/README.md' dot_claude/skills/mwk-learn/SKILL.md \
  && ok "mwk-learn writes to ~/projects/learning, in git" \
  || no "mwk-learn writes to ~/projects/learning" "still writing somewhere that is not backed up"
grep -qi 'artifact:\|29200' dot_claude/skills/mwk-learn/SKILL.md \
  && no "mwk-learn has no page or artifact machinery left" "found one" \
  || ok "mwk-learn has no page or artifact machinery left"
# Every skill declares the binaries it calls, and each is either pinned in mise.toml or a
# thing every machine has. mwk-save was written needing gh and nothing installed it.
for d in dot_claude/skills/*/; do
  name=$(basename "$d")
  req=$(grep -oE '<!-- requires: [a-z0-9 -]+ -->' "$d/SKILL.md" | sed 's/<!-- requires: //; s/ -->//')
  [ -n "$req" ] || { no "$name declares what it requires" "no <!-- requires: … --> line"; continue; }
  for b in $req; do
    case "$b" in git|curl|sh|bash|python3) ok "$name requires $b (system)";;
      mwk) ok "$name requires mwk (the kit's own)";;
      gh)  grep -q 'cli/cli' mise.toml && ok "$name requires gh — pinned" || no "$name requires gh" "not in mise.toml";;
      *)   grep -q "/$b\"" mise.toml && ok "$name requires $b — pinned" || no "$name requires $b" "not in mise.toml";;
    esac
  done
done

# BOTH DIRECTIONS, because a rename is the string-replace-that-silently-misses in its most
# dangerous form: the skill still loads under its old directory name, so nothing fails —
# the documents just promise a name that no longer answers. Backticks are required: a bare
# /mwk-… also matches the repo path in github.com/matewishkey/mwk-genie.
offered=$(grep -ohE '`/mwk-[a-z]+`' README.md dot_claude/create_CLAUDE.md | tr -d '`/' | sort -u)
ondisk=$(for d in dot_claude/skills/*/; do basename "$d"; done | sort -u)
for s in $offered; do
  [ -f "dot_claude/skills/$s/SKILL.md" ] \
    && ok "the documents offer /$s, and it exists" \
    || no "the documents offer /$s" "no dot_claude/skills/$s/SKILL.md — a promised name that does not answer"
done
for s in $ondisk; do
  printf '%s\n' "$offered" | grep -qx "$s" \
    && ok "$s is offered to them, not just shipped" \
    || no "$s is offered to them" "installed but named in neither README.md nor create_CLAUDE.md"
done

head_ "Every URL handed to a stranger"
if command -v curl >/dev/null 2>&1; then
  urls=$(grep -rhoE 'https?://[A-Za-z0-9._~:/?#@!$&()*+,;=%-]+' \
          README.md prompts/ dot_claude/ install.sh mise.toml 2>/dev/null \
        | sed 's/[.,)]*$//' | sort -u \
        | grep -vE 'localhost|127\.0\.0\.1|example\.' \
        | grep -v 'mwk-genie/main/install.sh')   # 404 until v2 merges; tracked in #16
  for u in $urls; do
    code=$(curl -s -o /dev/null -m 15 -w '%{http_code}' -L "$u" 2>/dev/null)
    case "$code" in
      200|204) ok "$code  $u" ;;
      405)     ok "405  $u (POST-only endpoint — reachable)" ;;
      # An API a skill calls WITH a key answers 400/401 to a bare curl — that is the endpoint
      # existing and refusing, which is what /mwk-onboard relies on. Only for api.* hosts;
      # a page a person opens still has to be a 200.
      400|401|403) case "$u" in https://api.*) ok "$code  $u (needs a key — reachable)" ;;
                                 *) no "$code  $u" "not a 200" ;; esac ;;
      000)     no "unreachable  $u" "no response — a 404 here is a beginner's first five minutes" ;;
      *)       no "$code  $u" "not a 200" ;;
    esac
  done
else
  no "URL check" "curl is missing"
fi

printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
