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
  # python3 is for THIS SCRIPT's fixtures only — the kit never calls it (grepped: the only
  # python reference in the repo is this file). ubuntu:24.04 ships without it, and the
  # settings-merge fixture below was silently doing nothing because of that.
  apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates zsh python3 >/dev/null
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
  chk 'chezmoi on PATH'                         '. ~/.mwk-shell.sh; command -v chezmoi'
  chk 'jq on PATH (settings merge)'             '. ~/.mwk-shell.sh; command -v jq'
  chk 'gh on PATH (/mwk-save, /mwk-bug, /mwk-tasks)' '. ~/.mwk-shell.sh; command -v gh'
  chk '~/.mwk-shell.sh placed'                  'test -f ~/.mwk-shell.sh'
  chk '~/.claude/CLAUDE.md placed'              'test -f ~/.claude/CLAUDE.md'
  chk '~/.claude/settings.json placed'          'test -f ~/.claude/settings.json'
  chk 'settings.json says opus'                 'grep -q opus ~/.claude/settings.json'
  chk 'skills placed'                           'test -f ~/.claude/skills/mwk-save/SKILL.md'

  # Existing is not the same as usable. v2 shipped a green 'test -x ~/bin/mwk' for a day
  # while ~/bin was on nobody's PATH and the first command a person is told to run did not
  # exist. Ask whether it RUNS.
  chk 'mwk RUNS in a fresh interactive shell'   'bash -ic \"command -v mwk\"'
  chk 'ccc exists in a fresh interactive shell' 'bash -ic \"alias ccc\"'
  chk 'mwk with no args + no tty prints usage'  'mwk </dev/null | grep -q \"mwk add\"'
  chk 'mwk add refuses with no keyboard (exit 3)' 'mwk add X </dev/null >/dev/null 2>&1; [ \$? = 3 ]'
  chk 'mwk update is offered'                   'mwk </dev/null | grep -q \"mwk update\"'
  # The update path is install.sh re-run. It has to be safe on a machine that already has
  # everything — which is the ONLY state it is ever used in, and the state the old
  # \`git pull ... || true\` reported success from without doing anything.
  chk 'mwk update re-runs clean over a full install' '. ~/.mwk-shell.sh; mwk update </dev/null'
  chk '...and the kit still works afterwards'   'bash -ic \"command -v mwk\"'

  echo '  --- the bug that shipped live in v1 ---'
  # ⚠ grep -c EXITS 1 WHEN THE COUNT IS ZERO. The old fallback here was \`|| echo 0\`, which
  # therefore fired ON TOP OF grep's own \`0\` and made these variables the two-line string
  # \`0\\n0\` — never equal to 0 or to 1. On this suite's first ever run that turned a
  # perfectly correct uninstall into a red line. Let grep's own count stand, and default
  # only when the file is genuinely absent, which is the case that prints nothing at all.
  n=\$(su - guest -c 'grep -c mwk-shell.sh ~/.bashrc 2>/dev/null || true'); n=\${n:-0}
  ok 'source line in ~/.bashrc appears exactly once' \"\$([ \"\$n\" = 1 ] && echo PASS || echo \"FAIL (n=\$n)\")\"
  [ \"\$n\" = 1 ] || FAILED=1
  su - guest -c '. ~/.mwk-shell.sh; chezmoi apply --source ~/projects/mwk-genie' >/dev/null 2>&1 || true
  n2=\$(su - guest -c 'grep -c mwk-shell.sh ~/.bashrc 2>/dev/null || true'); n2=\${n2:-0}
  ok 'still exactly once after a second apply' \"\$([ \"\$n2\" = 1 ] && echo PASS || echo \"FAIL (n=\$n2)\")\"
  [ \"\$n2\" = 1 ] || FAILED=1

  echo '  --- settings.json is merged, never replaced ---'
  # The failure this guards: a plain managed file reverts Claude Code's own writes on the
  # next apply, silently uninstalling the person's plugins.
  #
  # ⚠ THIS CHECK DID NOT RUN FOR ITS FIRST EVER EXECUTION, and that is the more dangerous
  # half of this repo's favourite bug. ubuntu:24.04 has no python3, the heredoc was guarded
  # `2>/dev/null || true`, so the fixture was never planted and the assertion below was
  # grepping for a key that had never existed. It reported FAIL, which was luck — the same
  # shape reports PASS just as easily, and then the suite is the thing lying to you.
  # So: plant it, ASSERT THE FIXTURE LANDED, and only then test what survives.
  su - guest -c 'python3 - <<PY
import json,os
p=os.path.expanduser(\"~/.claude/settings.json\")
d=json.load(open(p)); d[\"enabledPlugins\"]={\"someone/thing\":True}; json.dump(d,open(p,\"w\"))
PY'
  chk 'the fixture itself was planted (precondition)' 'grep -q someone/thing ~/.claude/settings.json'
  su - guest -c '. ~/.mwk-shell.sh; chezmoi apply --source ~/projects/mwk-genie' >/dev/null 2>&1 || true
  chk 'a key Claude Code wrote survives an apply'  'grep -q someone/thing ~/.claude/settings.json'
  chk 'and ours is still asserted'                 'grep -q opus ~/.claude/settings.json'

  echo '  --- take it all off, then put it back on ---'
  # This is the cycle the kit has to survive, because it is the one used to test it. A
  # second install onto a machine that still has the first is not what a new person meets.
  su - guest -c 'mkdir -p ~/.config/sops/age && echo AGE-SECRET-KEY-1FAKE > ~/.config/sops/age/keys.txt'
  su - guest -c 'sh ~/projects/mwk-genie/uninstall.sh --all' >/dev/null 2>&1 || { echo '  UNINSTALL FAILED'; FAILED=1; }

  for leftover in .mwk-shell.sh bin/mwk .claude/skills/mwk-save projects/mwk-genie .config/chezmoi; do
    if su - guest -c \"test -e ~/\$leftover\" 2>/dev/null; then ok \"gone: ~/\$leftover\" FAIL; FAILED=1
    else ok \"gone: ~/\$leftover\" PASS; fi
  done
  n3=\$(su - guest -c 'grep -c mwk-shell.sh ~/.bashrc 2>/dev/null || true'); n3=\${n3:-0}
  ok 'the source line is out of ~/.bashrc' \"\$([ \"\$n3\" = 0 ] && echo PASS || echo \"FAIL (n=\$n3)\")\"
  [ \"\$n3\" = 0 ] || FAILED=1
  chk 'ccc is gone from a fresh shell'          '! bash -ic \"alias ccc\"'

  # Their keys were moved, not erased. Deleting a password store on a typo would be the
  # worst thing this kit could do, so the trash is load-bearing rather than politeness.
  chk 'the key is in the trash, not erased'     'ls ~/.local/share/Trash/files/keys.txt'

  su - guest -c 'curl -fsSL https://raw.githubusercontent.com/matewishkey/mwk-genie/$REF/install.sh | MWK_REF=$REF sh' >/dev/null 2>&1 \
    || { echo '  REINSTALL FAILED'; FAILED=1; }
  chk 'reinstall: mwk runs again'               'bash -ic \"command -v mwk\"'
  chk 'reinstall: ccc is back'                  'bash -ic \"alias ccc\"'

  echo; [ \"\$FAILED\" = 0 ] && echo 'ALL GREEN' || { echo 'SOME FAILED'; exit 1; }
"
