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
# Anchor on the assignment, not the file: the comment above it says the word "latest".
# A check that can never go green is how people learn to ignore the suite.
latest=$(grep -cE '^"aqua:[^"]+" *= *"latest"' mise.toml)
is "no tool floats on \"latest\"" "$latest" "0"
for t in chezmoi sops age miniserve jq cli; do
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
# The help text names the flag in order to say it does not exist. Look at the arg parser.
v=$(grep -cE '^\s+(--value|-v)\)' bin/executable_mwk)
is "there is no --value flag (argv, ps and history)" "$v" "0"
for guard in 'refusing: the page directory is inside the store' \
             'refusing: the store is inside the page directory' \
             '\-i 127.0.0.1' '\-P '; do
  grep -q -- "$guard" bin/executable_mwk && ok "site guard: ${guard:0:44}" \
    || no "site guard: ${guard:0:44}" "missing — miniserve binds 0.0.0.0 and follows symlinks by default"
done
grep -q 'unset SOPS_AGE_KEY' bin/executable_mwk && ok "the master key is unset before the wrapped command runs" \
  || no "the master key is unset before the wrapped command runs" "it would be inherited"

# ── the add-eats-the-store class ──────────────────────────────────────────────────────
# Three separate mistakes had to line up for `mwk add` to replace the whole store with one
# key, and each of these asserts one of them is gone. They are cheap; the functional test
# further down is the one that would actually catch a new way of doing the same thing.
if sed -n '/^have_tty()/p' bin/executable_mwk | grep -q '\-t 1'; then
  no "have_tty does not ask about stdout" "it tests [ -t 1 ], which is false inside every pipeline — so a person reading in one looks like an agent"
else ok "have_tty does not ask about stdout"; fi
if sed -n '/^sops_d()/,/^}/p' bin/executable_mwk | grep -q 'locked_msg'; then
  no "sops_d never exits by itself" "locked_msg does exit 3, and in a pipeline that leaves only the subshell — the caller writes anyway"
else ok "sops_d never exits by itself, it returns non-zero"; fi
add_body=$(sed -n '/^cmd_add()/,/^}/p' bin/executable_mwk)
printf '%s\n' "$add_body" | grep -q 'unlock_once' \
  && ok "cmd_add unlocks in the main shell, before it reads" \
  || no "cmd_add unlocks before it reads" "the prompt would land inside a pipeline"
printf '%s\n' "$add_body" | grep -q 'die "could not read what is already in your store' \
  && ok "…and a failed read stops it, rather than writing anyway" \
  || no "a failed read stops cmd_add" "this is the bug that ate the store"
printf '%s\n' "$add_body" | grep -q 'did not come back right' \
  && ok "…and it reads the store back and checks the old names survived" \
  || no "cmd_add asserts its own result" "the one file with no backup deserves a read-back"

head_ "…and the same property, actually run"
# EVERYTHING ABOVE THIS LINE IS A GREP. This is the property itself: add two keys, and both
# are still there afterwards. It is the only check in the file that runs mwk against a real
# store, and it exists because every static check in this section would have passed happily
# on the day `mwk add` started replacing the store with a single key.
#
# It needs sops, age and a pty. On this fleet those tools are mise-managed inside the kit
# rather than on PATH, so try that before giving up — and if they are genuinely missing,
# SAY the check did not run rather than counting it as a pass.
if ! command -v sops >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
  eval "$(mise env -s bash 2>/dev/null)" || true
fi
TMO=""; command -v timeout >/dev/null 2>&1 && TMO="timeout 45"
pty() {   # run "$1" with a controlling terminal. util-linux and BSD `script` differ.
  if script --version 2>&1 | grep -qi util-linux; then $TMO script -qec "$1" /dev/null
  else $TMO script -q /dev/null /bin/sh -c "$1"; fi
}
if command -v sops >/dev/null 2>&1 && command -v age >/dev/null 2>&1 \
   && command -v script >/dev/null 2>&1; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  cp bin/executable_mwk "$T/mwk"; chmod +x "$T/mwk"; mkdir -p "$T/site"
  # Both overrides, so nothing here can reach the real home. ports.tsv follows MWK_SITE.
  export MWK_STORE="$T/store" MWK_SITE="$T/site"
  PW='check-suite-passphrase'
  printf '\n%s\n%s\n' "$PW" "$PW" | pty "$T/mwk init" >/dev/null 2>&1
  if [ -f "$T/store/identity.age" ]; then
    ok "mwk init makes a passphrase-encrypted store"
    printf '%s\nvalue-a\n' "$PW" | pty "$T/mwk add ALPHA global" >/dev/null 2>&1
    printf '%s\nvalue-b\n' "$PW" | pty "$T/mwk add BETA global"  >/dev/null 2>&1
    got=$(printf '%s\n' "$PW" | pty "$T/mwk list" 2>/dev/null \
          | grep -aoE '^(ALPHA|BETA|GAMMA)' | sort -u | tr '\n' ' ')
    is "adding a second key keeps the first" "$got" "ALPHA BETA "
    # And the other half: a wrong password must leave the store exactly as it was. It used
    # to print "Stored", exit 0, and take both of the keys above with it.
    printf 'not-the-password\nvalue-c\n' | pty "$T/mwk add GAMMA global" >/dev/null 2>&1
    after=$(printf '%s\n' "$PW" | pty "$T/mwk list" 2>/dev/null \
            | grep -aoE '^(ALPHA|BETA|GAMMA)' | sort -u | tr '\n' ' ')
    is "a wrong password changes nothing at all" "$after" "ALPHA BETA "
  else
    no "mwk init makes a store (nothing below it ran)" "no identity.age was written"
  fi
  unset MWK_STORE MWK_SITE
else
  no "the store's behaviour was tested for real (SKIPPED)" \
     "needs sops, age and script on PATH — this did not run, and that is not a pass"
fi

head_ "Showing a project in a browser"
grep -q 'cmd_serve' bin/executable_mwk && ok "mwk serve exists" \
  || no "mwk serve exists" "mwk port hands out an address with nothing listening on it"
grep -qE '^  serve\) shift; cmd_serve' bin/executable_mwk && ok "…and the dispatcher reaches it" \
  || no "mwk serve is reachable" "the function exists but no argument gets to it"
serve_body=$(sed -n '/^cmd_serve()/,/^}/p' bin/executable_mwk)
n=$(printf '%s\n' "$serve_body" | grep -cE 'miniserve -i 127\.0\.0\.1 -P ')
[ "$n" -ge 2 ] && ok "every miniserve it starts is loopback-only and follows no symlinks ($n)" \
  || no "mwk serve binds loopback only" "miniserve binds 0.0.0.0 by default — this would be on the wifi"
for guard in '"\$HOME")' '"\$HOME/projects")' 'inside your key store'; do
  printf '%s\n' "$serve_body" | grep -q -- "$guard" && ok "it refuses to serve: ${guard}" \
    || no "it refuses to serve ${guard}" "one folder is the deal; everything at once is 'mwk files'"
done
grep -q 'write_projects_json' bin/executable_mwk && ok "mwk writes projects.json" \
  || no "mwk writes projects.json" "the page would have a reader and no writer, again"
grep -q "projects.json" mwk/site/index.html && ok "…and the page reads it" \
  || no "the page reads projects.json" "missing"
grep -q 'jq -Rs' bin/executable_mwk && ok "…built with jq, not by hand" \
  || no "projects.json is built with jq" "a folder name with a quote in it would break the page silently"
# Liveness must be asked of the port, not remembered from a file: a "running" flag is wrong
# the moment the laptop sleeps, and it is wrong in the reassuring direction.
grep -q "mode:'no-cors'" mwk/site/index.html && ok "the running dot asks the port, not a stored flag" \
  || no "the running dot asks the port" "a remembered flag goes green-and-wrong after a reboot"

head_ "The password page's Copy button"
# It shipped carrying index.html's script verbatim: that script looks up #queue, which is
# not on that page, and binds handlers only to buttons it builds itself. So the one command
# on the page — mwk rekey — could not be copied, and nothing said so.
n=$(grep -c 'data-c=' mwk/site/password.html || true)
[ "$n" -ge 1 ] && ok "it has $n command button(s)" || no "it has a command button" "none found"
grep -q 'querySelectorAll' mwk/site/password.html \
  && ok "…and something is actually bound to them" \
  || no "something is bound to the Copy button" "the button is decorative — this exact bug shipped"
q=$(grep -c "getElementById('queue')" mwk/site/password.html || true)
is "it does not look for #queue, which is not on this page" "$q" "0"

head_ "Only the right things reach a stranger's home directory"
# .chezmoiignore is an ALLOW-list and its patterns match TARGET names, not source names —
# get that wrong and it places NOTHING while looking correct. Assert both directions.
managed=$(chezmoi managed --source . 2>/dev/null)
for want in .claude/CLAUDE.md .claude/settings.json .claude/skills/mwk-save/SKILL.md \
            .mwk-shell.sh bin/mwk bin/mwk-debug mwk/site/index.html mwk/site/password.html; do
  printf '%s\n' "$managed" | grep -qx "$want" && ok "placed: $want" || no "placed: $want" "MISSING"
done
for never in debug-worker uninstall.sh README.md CLAUDE.md install.sh mise.toml mise.lock \
             test prompts docs mwk/site/queue.json mwk/site/projects.json; do
  printf '%s\n' "$managed" | grep -q "^$never" \
    && no "never placed: $never" "it is being copied into their home" || ok "never placed: $never"
done

head_ "Nothing guest-facing assumes our machines"
for term in td-sops 'work\.l' devproxy '192\.168' dotfiles-cz dokku healthchecks; do
  n=$(grep -rniI "$term" dot_claude/ mwk/ bin/ prompts/ 2>/dev/null | wc -l)
  is "no reference to $term" "$n" "0"
done

head_ "It can be taken back off"
sh -n uninstall.sh && ok "uninstall.sh is valid sh" || no "uninstall.sh is valid sh" "syntax error"
grep -q 'trash_it "$HOME/.mwk"' uninstall.sh \
  && ok "the key store is TRASHED, never rm -rf'd" \
  || no "the key store is trashed, never rm -rf'd" "a password store must survive a typo"
grep -q 'cmd_uninstall' bin/executable_mwk && ok "mwk uninstall reaches it" || no "mwk uninstall reaches it" "missing"
grep -q '\[ -t 0 \] || return 1' uninstall.sh \
  && ok "no keyboard means no consent — it does not assume yes" \
  || no "no keyboard means no consent" "an unattended run could delete their keys"

head_ "Debug mode is off unless it is switched on"
# The property that matters: a guest must never upload anything. Assert the silence, not
# the intention — with no token this exits 0 having sent nothing.
out=$(MWK_DEBUG= sh bin/executable_mwk-debug send /etc/hostname 2>&1); rc=$?
is "no token: exits 0" "$rc" "0"
is "no token: says nothing"  "$out" ""
grep -q 'AGE-SECRET-KEY' bin/executable_mwk-debug && ok "the redactor knows age keys" || no "the redactor knows age keys" "missing"
grep -q "s|\$HOME|~|g" bin/executable_mwk-debug && ok "and strips \$HOME before anything else" \
  || no "it strips \$HOME" "a username would survive inside a path"
grep -q 'debug.matewishkey.com' bin/executable_mwk-debug && ok "endpoint is pinned, not guessed" || no "endpoint is pinned" "missing"

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
# The credit must stay commented. Putting our name on a stranger's site by default is the
# thing the README promises we do not do.
# Each template must carry the credit, and it must be inside a comment. The old version of
# this check counted lines that were not themselves a comment marker, which passed whatever
# happened — the credit sits BETWEEN the markers, never on one.
for f in site-templates/*/*.html; do
  n=$(grep -c 'matewishkey' "$f" || true)
  is "$(basename $(dirname "$f"))/$(basename "$f") carries the credit" "$n" "1"
  # In-comment test: strip every <!-- ... --> block, then look again. If the stripper is
  # missing, SAY SO rather than defaulting to 0 — a check that passes when it cannot run is
  # the exact failure this file opens by warning about.
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
managed=$(chezmoi managed --source . 2>/dev/null)
printf '%s\n' "$managed" | grep -q 'site-templates' \
  && no "templates are NOT copied into their home" "they live in the kit folder" \
  || ok "templates are not copied into their home"

head_ "The menu numbers match the handlers"
# This exact bug shipped: an edit renumbered the case arms and silently did not match the
# printed block, so there were TWO number 3s and uninstall was unreachable. It read fine.
printed=$(sed -n '/What would you like to do/,/Type a number/p' bin/executable_mwk \
          | grep -oE '^ +[0-9]+' | tr -d ' ' | tr '\n' ' ')
handled=$(sed -n '/read -r choice/,/esac/p' bin/executable_mwk \
          | grep -oE '^ +[0-9]+\)' | tr -d ' )' | tr '\n' ' ')
is "every printed number has a handler, in order" "$printed" "$handled"
dupes=$(printf '%s' "$printed" | tr ' ' '\n' | sort | uniq -d | tr -d '\n')
is "no number appears twice in the menu" "$dupes" ""

head_ "The file browser"
grep -q 'cmd_files' bin/executable_mwk && ok "mwk files exists" || no "mwk files exists" "missing"
grep -q 'PORT_FILES=29201' bin/executable_mwk && ok "it is on 29201, beside the page" || no "it is on 29201" "wrong port"
grep -E '^\s*(exec |setsid |nohup )?miniserve ' bin/executable_mwk | grep -q 'upload-files\|--mkdir' \
  && no "the browser is read-only" "upload or mkdir is enabled — a delete button over their own work" \
  || ok "the browser is read-only"
# Loopback binding does not stop a web page: a site can rebind its own domain to 127.0.0.1
# and read the tree from the victim's browser. Basic auth does stop it, because a browser
# will not attach credentials cross-origin.
grep -q 'auth "mwk:\$tok"' bin/executable_mwk \
  && ok "and it is behind a per-run password (DNS rebinding)" \
  || no "the file browser has per-run auth" "~/projects would be readable by any site the person visits"
grep -q 'head -c 16 /dev/urandom' bin/executable_mwk \
  && ok "the password is random per run, not fixed" || no "the password is random per run" "a fixed one is no password"

head_ "Colour"
for f in install.sh uninstall.sh bin/executable_mwk; do
  grep -q '226;52;43' "$f" && ok "$f carries the brand red" || no "$f carries the brand red" "missing"
  grep -q 'if \[ -t 1 \]' "$f" && ok "$f: no colour when piped" \
    || no "$f: no colour when piped" "escape codes would land in logs and captured values"
done
grep -q 'PROMPT=' dot_mwk-shell.sh.tmpl && grep -q 'PS1=' dot_mwk-shell.sh.tmpl \
  && ok "a prompt is set for both zsh and bash" || no "a prompt is set for both shells" "missing"

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
# The rule is "red is never body text", which counting the hex does not test — the token
# definition and the logo are both legitimate. Test the rule instead: red may be declared,
# and it may fill the block, but nothing may set it as a text colour.
for site in mwk/site/index.html mwk/site/password.html; do
  grep -q 'e2342b' "$site" && ok "$(basename "$site"): the block carries the brand red" \
    || no "$(basename "$site"): the block carries the brand red" "missing"
  body_red=$(grep -c 'color:var(--red)[^-]' "$site" || true)
  is "$(basename "$site"): red is never body text" "$body_red" "0"
done
site=mwk/site/index.html
grep -q 'password.html' "$site" && ok "the page links the password guidance" \
  || no "the page links the password guidance" "a guest would never find it"
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
        | sed 's/[.,)]*$//' | sort -u \
        | grep -vE 'localhost|127\.0\.0\.1|example\.' \
        | grep -v 'mwk-genie/main/install.sh')   # 404 until v2 merges; tracked in #16
  for u in $urls; do
    code=$(curl -s -o /dev/null -m 15 -w '%{http_code}' -L "$u" 2>/dev/null)
    case "$code" in
      200|204) ok "$code  $u" ;;
      405)     ok "405  $u (POST-only endpoint — reachable)" ;;
      000)     no "unreachable  $u" "no response — a 404 here is a beginner's first five minutes" ;;
      *)       no "$code  $u" "not a 200" ;;
    esac
  done
else
  no "URL check" "curl is missing"
fi

printf '\n\033[1m%d passed, %d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
