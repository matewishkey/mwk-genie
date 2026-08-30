#!/usr/bin/env bash
# The real thing, in a clean container: ubuntu:24.04 with no curl, no git, nothing —
# running the actual one-liner against the actual GitHub branch.
#
#   bash test/rehearse.sh            # tests main
#   bash test/rehearse.sh v2         # tests a branch
#   bash test/rehearse.sh <sha>      # tests one commit — USE THIS after a push
#
# ⚠ USE A COMMIT SHA WHEN YOU HAVE JUST PUSHED. raw.githubusercontent.com serves a stale
# copy of a branch path for a few minutes after a push; that cost two confusing runs where
# the fix was in and the test was still fetching the old file. A SHA path is never stale.
#
# NOTHING IS PRE-PLACED. A test that arranges the precondition it is meant to prove is
# worse than no test — this repo has three logged instances of exactly that, all green for
# months. If you find yourself adding a step here to make it pass, the bug is in the thing
# being tested.
#
# ⚠ WRITTEN, NOT YET RUN in this form.
set -euo pipefail
REF="${1:-main}"
echo "Rehearsing ref: $REF"

docker run --rm ubuntu:24.04 bash -euc "
  apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates zsh >/dev/null
  useradd -m -s /bin/bash guest

  su - guest -c 'curl -fsSL https://raw.githubusercontent.com/matewishkey/mwk-genie/$REF/install.sh | MWK_REF=$REF sh' \
    || { echo 'INSTALL FAILED'; exit 1; }

  echo; echo '===== ASSERTIONS ====='
  FAILED=0
  ok(){ printf '  %-54s %s\n' \"\$1\" \"\$2\"; }
  chk(){ if su - guest -c \"\$2\" >/dev/null 2>&1; then ok \"\$1\" PASS; else ok \"\$1\" FAIL; FAILED=1; fi; }

  chk 'kit is at ~/projects/mwk-genie'          'test -f ~/projects/mwk-genie/mise.toml'
  chk 'mise installed'                          'test -x ~/.local/bin/mise'
  chk 'sops on PATH'                            '. ~/.mwk-shell.sh; command -v sops'
  chk 'age AND age-keygen on PATH'              '. ~/.mwk-shell.sh; command -v age && command -v age-keygen'
  chk 'miniserve on PATH'                       '. ~/.mwk-shell.sh; command -v miniserve'
  chk 'chezmoi on PATH'                         '. ~/.mwk-shell.sh; command -v chezmoi'
  chk 'jq on PATH (settings merge + mwk queue)' '. ~/.mwk-shell.sh; command -v jq'
  chk '~/.mwk-shell.sh placed'                  'test -f ~/.mwk-shell.sh'
  chk '~/.claude/CLAUDE.md placed'              'test -f ~/.claude/CLAUDE.md'
  chk '~/.claude/settings.json placed'          'test -f ~/.claude/settings.json'
  chk 'settings.json says opus'                 'grep -q opus ~/.claude/settings.json'
  chk 'skills placed'                           'test -f ~/.claude/skills/mwk-save/SKILL.md'
  chk 'the page was placed'                     'test -f ~/mwk/site/index.html'

  # Existing is not the same as usable. v2 shipped a green 'test -x ~/bin/mwk' for a day
  # while ~/bin was on nobody's PATH and the first command a person is told to run did not
  # exist. Ask whether it RUNS.
  chk 'mwk RUNS in a fresh interactive shell'   'bash -ic \"command -v mwk\"'
  chk 'ccc exists in a fresh interactive shell' 'bash -ic \"alias ccc\"'
  chk 'mwk with no args + no tty prints usage'  'mwk </dev/null | grep -q \"mwk init\"'

  echo '  --- the bug that shipped live in v1 ---'
  n=\$(su - guest -c 'grep -c mwk-shell.sh ~/.bashrc' 2>/dev/null || echo 0)
  ok 'source line in ~/.bashrc appears exactly once' \"\$([ \"\$n\" = 1 ] && echo PASS || echo \"FAIL (n=\$n)\")\"
  [ \"\$n\" = 1 ] || FAILED=1
  su - guest -c '. ~/.mwk-shell.sh; chezmoi apply --source ~/projects/mwk-genie' >/dev/null 2>&1 || true
  n2=\$(su - guest -c 'grep -c mwk-shell.sh ~/.bashrc' 2>/dev/null || echo 0)
  ok 'still exactly once after a second apply' \"\$([ \"\$n2\" = 1 ] && echo PASS || echo \"FAIL (n=\$n2)\")\"
  [ \"\$n2\" = 1 ] || FAILED=1

  echo '  --- settings.json is merged, never replaced ---'
  # The failure this guards: a plain managed file reverts Claude Code's own writes on the
  # next apply, silently uninstalling the person's plugins.
  su - guest -c 'python3 - <<PY 2>/dev/null || true
import json,os
p=os.path.expanduser(\"~/.claude/settings.json\")
d=json.load(open(p)); d[\"enabledPlugins\"]={\"someone/thing\":True}; json.dump(d,open(p,\"w\"))
PY'
  su - guest -c '. ~/.mwk-shell.sh; chezmoi apply --source ~/projects/mwk-genie' >/dev/null 2>&1 || true
  chk 'a key Claude Code wrote survives an apply'  'grep -q someone/thing ~/.claude/settings.json'
  chk 'and ours is still asserted'                 'grep -q opus ~/.claude/settings.json'

  echo; [ \"\$FAILED\" = 0 ] && echo 'ALL GREEN' || { echo 'SOME FAILED'; exit 1; }
"
