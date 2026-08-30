#!/bin/sh
# The whole thing, on a real machine, in one command:
#
#   curl -fsSL https://raw.githubusercontent.com/matewishkey/mwk-genie/<ref>/test/on-this-machine.sh \
#     | MWK_REF=<ref> MWK_DEBUG=1 sh
#
# It installs, checks, exercises, uninstalls, reinstalls, and ships ONE log with all of it —
# so the failure and everything leading up to it arrive together rather than as a screenshot.
#
# ⚠ THIS INSTALLS ON THE MACHINE YOU RUN IT ON. That is the point: nothing here is mocked.
# It finishes by uninstalling and reinstalling, so the machine is left set up, not clean.
#
# What it CANNOT test, and says so at the end: anything needing a keyboard. `mwk init`
# refuses without a TTY by design, so the store is checked for that refusal and the real
# password path is left to a human.
set -u

REF="${MWK_REF:-main}"
KIT="$HOME/projects/mwk-genie"
RAW="https://raw.githubusercontent.com/matewishkey/mwk-genie/$REF"

if [ -t 1 ]; then
  case "${COLORTERM:-}" in truecolor|24bit) RED=$(printf '\033[38;2;226;52;43m');; *) RED=$(printf '\033[38;5;203m');; esac
  B=$(printf '\033[1m'); D=$(printf '\033[2m'); G=$(printf '\033[32m'); Y=$(printf '\033[33m'); R=$(printf '\033[0m')
else RED=''; B=''; D=''; G=''; Y=''; R=''; fi

PASS=0; FAIL=0
phase(){ printf '\n%s%s── %s%s\n' "$B" "$RED" "$1" "$R"; }
ok(){ printf '  %s✓%s %s\n' "$G" "$R" "$1"; PASS=$((PASS+1)); }
bad(){ printf '  %s✗%s %s\n' "$RED" "$R" "$1"; [ $# -gt 1 ] && printf '      %s%s%s\n' "$D" "$2" "$R"; FAIL=$((FAIL+1)); }
try(){ if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1" "$2"; fi; }
note(){ printf '  %s%s%s\n' "$D" "$1" "$R"; }

printf '\n%s%sTesting mwk-genie on this machine%s\n' "$B" "$RED" "$R"
note "ref $REF · $(uname -s) $(uname -m) · $(date)"
[ -n "${MWK_DEBUG:-}" ] && note "debug on — one log for all of it at the end" \
                        || note "debug OFF — set MWK_DEBUG=1 to have the log sent"

phase "1 · Install"
curl -fsSL "$RAW/install.sh" | MWK_REF="$REF" MWK_DEBUG= sh 2>&1 | sed 's/^/  /'
[ -f "$KIT/mise.toml" ] && ok "the kit is at ~/projects/mwk-genie" || bad "the kit landed" "no mise.toml"

# Everything from here needs the PATH the install just created, which this shell does not
# have — same trap the agent hits. Source it rather than opening a new window.
[ -f "$HOME/.mwk-shell.sh" ] && . "$HOME/.mwk-shell.sh"

phase "2 · The fast checks"
if [ -f "$KIT/test/check.sh" ]; then
  ( cd "$KIT" && bash test/check.sh ) 2>&1 | sed 's/^/  /'
  note "counts above are check.sh's own"
else bad "check.sh is present" "not in the kit"; fi

phase "3 · Is it actually usable"
try "mwk runs"                      "command -v mwk"
try "mwk-debug runs"                "command -v mwk-debug"
try "sops, age, age-keygen"         "command -v sops && command -v age && command -v age-keygen"
try "miniserve, jq, gh"             "command -v miniserve && command -v jq && command -v gh"
try "claude"                        "command -v claude"
try "ccc in a fresh login shell"    "\$SHELL -lic 'alias ccc' 2>/dev/null | grep -q claude"
try "the rules file landed"         "test -f \$HOME/.claude/CLAUDE.md"
try "settings say opus"             "grep -q opus \$HOME/.claude/settings.json"
try "all five skills"               "test \$(ls -d \$HOME/.claude/skills/mwk-* | wc -l) -eq 5"
try "their page exists"             "test -f \$HOME/mwk/site/index.html"
try "the password page exists"      "test -f \$HOME/mwk/site/password.html"
try "the starter websites"          "test -f \$KIT/site-templates/one-page/index.html"
try "nothing of ours in their home" "! test -e \$HOME/debug-worker && ! test -e \$HOME/uninstall.sh"

phase "4 · The two servers"
mwk site  >/dev/null 2>&1
mwk files >/dev/null 2>&1
sleep 2
try "the page serves on 29200"    "curl -sf -m 5 http://127.0.0.1:29200/ -o /dev/null"
try "the files browse on 29201"   "curl -sf -m 5 http://127.0.0.1:29201/ -o /dev/null"
try "29200 is NOT on the network" "! curl -sf -m 4 http://\$(hostname):29200/ -o /dev/null"
p=$(cd "$HOME" && mwk port 2>/dev/null)
case "$p" in 292*) ok "mwk port gave $p"; q=$(cd "$HOME" && mwk port 2>/dev/null)
  [ "$p" = "$q" ] && ok "and the same folder gets it again" || bad "port is stable" "$p then $q" ;;
  *) bad "mwk port gave a number" "got [$p]" ;; esac

# A project, served on its own number — the thing `mwk port` used to only promise. Built
# from a real starter template rather than an echoed <html>, so this also proves the
# templates are copyable and that what a beginner would actually make is what gets served.
DEMO="$HOME/projects/on-this-machine-demo"
mkdir -p "$DEMO"
cp "$KIT/site-templates/one-page/index.html" "$KIT/site-templates/one-page/mwk.css" "$DEMO/" 2>/dev/null
( cd "$DEMO" && mwk serve >/dev/null 2>&1 )
sleep 2
dp=$(cd "$DEMO" && mwk port 2>/dev/null)
case "$dp" in
  292*)
    try "a project serves on its own port ($dp)"   "curl -sf -m 5 http://127.0.0.1:$dp/ -o /dev/null"
    try "…and its stylesheet came with it"         "curl -sf -m 5 http://127.0.0.1:$dp/mwk.css -o /dev/null"
    try "…and it is NOT on the network"            "! curl -sf -m 4 http://\$(hostname):$dp/ -o /dev/null"
    try "it appears on their page"                 "curl -sf -m 5 http://127.0.0.1:29200/projects.json | grep -q on-this-machine-demo"
    try "…as parseable JSON"                       "curl -sf -m 5 http://127.0.0.1:29200/projects.json | jq -e . >/dev/null"
    try "serving it twice does not start a second" "cd $DEMO && mwk serve 2>&1 | grep -q 'Already open'"
    ;;
  *) bad "the demo project got a port" "got [$dp]" ;;
esac
try "mwk serve refuses your whole home"     "! mwk serve \$HOME >/dev/null 2>&1"
try "mwk serve refuses all of ~/projects"   "! mwk serve \$HOME/projects >/dev/null 2>&1"

phase "5 · The store refuses what it should"
out=$(mwk init </dev/null 2>&1); rc=$?
[ "$rc" = 3 ] && ok "mwk init refuses with no keyboard (exit 3)" || bad "mwk init refuses without a tty" "exit $rc"
printf '%s' "$out" | grep -q 'your own terminal' && ok "and says why, in words" || bad "the refusal explains itself"
try "mwk with no args prints usage when piped" "mwk </dev/null | grep -q 'mwk init'"

phase "6 · Take it off, put it back on"
sh "$KIT/uninstall.sh" --all >/dev/null 2>&1
try "the shell file is gone"        "! test -f \$HOME/.mwk-shell.sh"
try "mwk is gone"                   "! test -x \$HOME/bin/mwk"
try "the skills are gone"           "! test -d \$HOME/.claude/skills/mwk-save"
try "the kit folder is gone"        "! test -d \$KIT"
try "the rc files are unhooked"     "! grep -q mwk-shell \$HOME/.zshrc 2>/dev/null && ! grep -q mwk-shell \$HOME/.bashrc 2>/dev/null"
curl -fsSL "$RAW/install.sh" | MWK_REF="$REF" MWK_DEBUG= sh >/dev/null 2>&1
[ -f "$HOME/.mwk-shell.sh" ] && . "$HOME/.mwk-shell.sh"
try "reinstall put mwk back"        "command -v mwk"
try "reinstall put the page back"   "test -f \$HOME/mwk/site/index.html"
# Uninstall trashes ~/mwk, and ports.tsv lives in it — so the project list is genuinely
# gone here, not merely stale. Re-registering is the real check, not a repeat of phase 4.
( cd "$DEMO" && mwk port >/dev/null 2>&1 )
try "the project list rebuilds after a reinstall" \
    "curl -sf -m 5 http://127.0.0.1:29200/projects.json | grep -q on-this-machine-demo"

printf '\n%s%s%s passed, %s failed%s\n' "$B" "$G" "$PASS" "$FAIL" "$R"
cat <<EOF

  ${Y}Not tested here, because it needs your hands:${R}
    mwk init      making the master password — it refuses without a keyboard, on purpose
    mwk add       same
    GitHub login  the device-code flow, in a real session
    iTerm2        only installs on a Mac, and only if it was not there already
    the prompts   whether they read well to somebody who has never done this

  Open http://127.0.0.1:29200/ and http://127.0.0.1:29201/ and have a look.
  The page should list one project, ${B}on-this-machine-demo${R}${Y}, with a green dot beside it.
  That folder is left in ~/projects on purpose — it is a real starter site, and
  deleting it would leave the page pointing at somewhere that is not there.${R}

EOF
