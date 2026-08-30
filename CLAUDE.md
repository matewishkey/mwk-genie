# mwk-genie — agent notes

The starter kit for **[Mate Wish Key](https://matewishkey.com)**: an AI agent running on somebody's
own computer, set up for a person who has never opened a terminal. One question, two things to
paste, and no password. `README.md` is the front door for a human; this file is the stuff that will
bite you.

**THERE ARE TWO `CLAUDE.md` FILES HERE AND THEY HAVE NOTHING TO DO WITH EACH OTHER.** This one is
notes for whoever works ON the kit. `dot_claude/create_CLAUDE.md` is a **product artefact** — chezmoi
places it at a stranger's `~/.claude/CLAUDE.md` and it becomes the rules their agent lives by.
Editing the wrong one is silent: nothing fails, and either the kit stops working or a beginner gets
instructions meant for you.

## How v2 works, in one pass

```
prompt one  (browser)  → Mac or Windows? → WSL / Xcode CLT → Claude Code → start it with
                         --dangerously-skip-permissions
prompt two  (Claude)   → read install.sh and report → run it → prove it → a folder and a page
install.sh             → kit → mise → 6 pinned tools → Claude Code → mise use -g → chezmoi apply
chezmoi                → ~/.mwk-shell.sh, ~/bin/mwk, ~/.claude/{CLAUDE.md,settings.json,skills/},
                         ~/mwk/site/, and on macOS iTerm2
```

**It is not a plugin.** Skills are placed straight at `~/.claude/skills/mwk-*/SKILL.md`, which
loads with no marketplace and no manifest. That deleted the three-names-must-agree rule, the
version match, and the install step. The prefix is in the directory name because user-level skills
share one flat namespace.

## The one question, and the two that were deleted

`.chezmoi.toml.tmpl` prompts for **nothing**. The single question — Mac or Windows — lives in
`prompts/install.md`, because Windows needs WSL before a terminal exists and nothing later can ask.

**Removing the prompts removed a TTY requirement, and that unblocked two things at once.** chezmoi
needed a terminal only because it was asking; with nothing to ask, an agent can run `install.sh`,
and the 87-character one-liner never has to appear inside a prompt file.

- **Model** — deleted. Opus was settled on 2026-08-11 after testing sonnet. It is written by
  `dot_claude/modify_settings.json` instead, and **removing the question had removed the setting
  with it** for a while — Claude Code's own default is not opus.
- **Admin** — deleted, not answered. iTerm2 goes to `~/Applications`, which needs no password, so
  nothing in the flow uses `sudo` at all.
- **`ccc_mode`** — decided for them, in `.chezmoidata.yaml`, as `fast`. This repo argued the other
  way for months and mate overruled it on 2026-08-30. What makes it survivable is that the escape
  hatch is one character: `~/.mwk-shell.sh` ships both alias lines with one commented out, and the
  page says which to swap. **If that escape hatch ever stops shipping, the argument has to reopen.**

## The read-before-you-run guardrail

`prompts/setup.md` makes the agent read `install.sh` and answer four questions out loud: sudo,
writes outside `$HOME`, unexpected download hosts, deletions. A stranger cannot read it themselves,
and "trust us" is not an answer.

**The checklist must stay true of the script.** It listed three hosts while `install.sh` fetched
from four — `raw.githubusercontent.com` was missing, so the guardrail would have fired on its own
installer. **A guardrail that cries wolf the first time is ignored the second.** If you add a
download or a temp file to `install.sh`, update the list in the same commit.

## Things measured on real machines, so nobody re-derives them

| Fact | Consequence |
|---|---|
| `/usr/bin/git` and `/usr/bin/clang` share an inode on macOS — it is the xcode-select shim | `command -v git` is true with no dev tools. Ask `xcode-select -p`, not whether a file exists |
| macOS has **no `timeout`** and no `gtimeout` | Calling it exits 127. Every agent-side `mwk` read once reported "locked" forever |
| A stock Mac has **no pinentry and no gpg-agent** | sops reads `/dev/tty` itself. **The 600s cache window is Linux-only** — it was written here as a flat cross-platform fact and that was wrong |
| Binaries fetched by curl/Go carry `com.apple.provenance`, not `com.apple.quarantine` | Gatekeeper does not block the toolchain. **Never add a blanket `xattr -dr`** to "fix" it |
| The four checked at the time (chezmoi, sops, age, miniserve) are ad-hoc signed arm64 — jq and gh were pinned later and not re-checked | They exec on Apple Silicon. `spctl -a` says "rejected" for ad-hoc binaries — that is the assessment API, not exec enforcement |
| miniserve binds `0.0.0.0` and `[::]` by default and follows symlinks | Reproduced: a fetch from the LAN returned 200, and a symlink out of the served root returned the store's ciphertext |
| `mise` shims resolve from the config **in scope** | `mise.toml` is a project config, so tools were active only inside the kit. `mise use -g` fixes it |
| A plain chezmoi-managed `settings.json` | With no TTY it **aborts the whole apply**; with `--force` it reverts the file and destroys `enabledPlugins`. Use `modify_`; `.chezmoi.stdin` does not exist, so it must be a script |
| `nginx` ships **source only** — no binaries | It cannot be installed without a package manager. Caddy is in the aqua registry with mac and linux builds |
| miniserve 0.35.0 has **no `--allowed-hosts`** | Checked its `--help`. A Host allowlist is the direct fix for rebinding and it does not exist here |
| Binding to `127.0.0.1` does **not** stop a web page | A site can point its own domain at loopback and read the server same-origin. `mwk files` exposes all of `~/projects`, so it carries per-run basic auth; a browser will not send credentials cross-origin |
| `.chezmoiignore` patterns match the **target** name | `dot_claude/**` matches nothing — the target is `.claude/**`. Writing the source name places NOTHING while reading correctly |
| `A && B \|\| C && D` groups as `((A && B) \|\| C) && D` | A successful first branch still ran the second. Use `if/elif` |

## The store

`~/.mwk/` — a passphrase-encrypted age identity plus sops-encrypted dotenv files. The thing they
save in a password manager is **a password**, not a 74-character key, which is the whole reason for
that shape.

**The store is outside `~/mwk/`, and that is structural rather than tidy.** `~/mwk/site` is handed
to a web server. "It is a dotfile and miniserve hides those" survives until someone adds `-H`;
not being under the served root survives that. `mwk site` also refuses to start if the two
directories contain one another.

`init`, `add` and `rekey` refuse without a TTY — enforcement using the property that was measured,
not a convention to remember. No `--value` flag anywhere, deliberately: that removes argv, `ps` and
shell history as a class rather than mitigating them.

## The failure this repo keeps having

**A string replace that does not match is silent, and it looks exactly like one that worked.** It
has now happened three times: v1's green ticks counted nothing, an ignore file placed
nothing while reading correctly, and a menu renumbering left **two number 3s** with `uninstall`
listed nowhere — so "see what keys you have" ran *add a key*.

Every one was written confidently and reviewed as correct. The defence is not more care, it is
asserting the result: after an edit, read back the thing that should have changed. `test/check.sh`
now compares the menu's printed digits against its `case` arms, and asserts the placed-file list by
name in both directions.

## Debug mode

`MWK_DEBUG=1` sends a run's log to `debug.matewishkey.com` — a Cloudflare Worker, KV, 30-day
expiry. **Posting is open and reading needs a token**, deliberately: turning it on has to be one
word a person can type on a call, and what needed protecting was reading. The read token is in
`td-sops` at `apps/mwk-genie.enc.env`; the Worker holds its own copy, so rotating means both.

Guards, all measured against the live endpoint: a body not starting with `=== mwk ` is 400 before
it costs a KV write, 20 posts per IP per hour (post 19 → 201, post 20 → 429), 512 KB cap, reads
401 without the token. **The run id is built in the Worker, not taken from the caller** — otherwise
anyone posting could overwrite an existing run.

Redaction happens **on the way out**, not by trusting the log: `$HOME` first so a username cannot
survive inside a path, then age keys, `sk-`, `gh[pousr]_`, Slack, JWTs and long base64. The whole
point of a debug log is that it caught something nobody expected.

Two things in `install.sh`'s capture that are easy to break: the real stderr is kept on **fd 3**,
because everything else is redirected into the capture pipe and a confirmation written into the log
it is confirming is no confirmation; and the send is on an **EXIT trap**, because the run worth
reading is the one that failed and `set -e` never reaches the bottom of the file.

## Ports

Everything served lives in **292xx**: `29200` is their page, `29201` browses `~/projects`, and
`mwk port` gives each project the next number up from `29202` — the same one every time. One fixed
port breaks the moment there are two projects.

## The page

`~/mwk/site/index.html`, chezmoi-managed. It polls `queue.json`, which `mwk queue` writes — **the
page had a reader and no writer for a while**, and the mechanism the whole handover depends on was
a sentence in a JavaScript comment.

**The page is one-way.** It cannot tell the agent anything, so the agent must never wait on it —
it checks the world instead. And every queued command is printed in chat too, because a page that
is not running is nothing at all.

## The cross-repo coupling — editing a prompt here changes the live website

**`mergodon/matewishkey-web` FETCHES `prompts/install.md` and `prompts/setup.md` AT BUILD TIME**
(`src/data/genie-prompts.ts`) and renders them at **`matewishkey.com/wishes/put-the-genie-in-the-box/`**.
The `/how-to/` path 301s **to** `/wishes/`, not the reverse — this file had that backwards and told
people to write the redirect, which is the thing it warns against.

- It reads the **first** fenced block. A second fence above it publishes the wrong thing.
- It **caps `prompts/setup.md` at 60 columns and throws.** v2 unwraps them, so
  **matewishkey-web#77 must land before merging** or their build goes red.
- A missing prompt file does **not** fail — it serves a stale cached copy with a warning. Green and
  wrong is worse than red.

**The third coupling is hand-typed and nothing checks it.** `src/content/wishes/put-the-genie-in-the-box.mdx`
quotes the opening of what is now `dot_claude/create_CLAUDE.md`, and the prose around it says "two
prompts", "three stages", "it asks you three things" and "an `mwk` plugin" — all false in v2. Filed
in #77.

## Rules that survived v1 and still apply

**Verify identifiers.** Every URL here is handed to a stranger whose agent acts on it. `check.sh`
extracts URLs from the files that ship and curls them; it does not read a hand-kept list, because
that checked the URLs somebody remembered rather than the ones a stranger meets.

**A test that arranges its own preconditions is worse than no test.** Three of v1's green ticks
counted nothing. When a check goes green, ask what would have to be true for it to go red.

**Existing is not running.** `test -x ~/bin/mwk` passed for a day while `~/bin` was on nobody's
PATH and the first command a person is told to type did not exist.

**The show is mentioned twice, and no more** — that rule currently has **zero** homes, because v2
retired both. Unresolved, and mate's to decide.

**No disclaimer link.** Settled 2026-08-09 and still settled.

**Red is spent once**, on the block, which is the real `favicon.svg` inlined verbatim. Copy buttons
stay neutral.

## Test it before you push

```
bash test/check.sh                    # seconds, no Docker
bash test/rehearse.sh <sha>           # minutes, Docker, install → uninstall → reinstall
curl … test/on-this-machine.sh | sh   # a REAL machine. See test/README.md
```

The third one installs on the machine it runs on and is the only way to test macOS. It ships one
debug log for all six phases.

Pass a **commit SHA**, not a branch — `raw.githubusercontent.com` serves a stale branch for minutes
after a push, and that has already cost two runs.

## Still open — all four are filed

| # | |
|---|---|
| **#13** | `mwk` menu option 1 is a stub. It is the first thing on the front door and the one that does nothing. The issue carries the `input/` + `archive/` convention it should build |
| **#14** | The show is mentioned in **zero** places and the rule is exactly two. A decision about tone, not a sweep |
| **#15** | Caddy as the shared front for project sites. nginx cannot be used — source only. `auto_https off` and `admin off` are load-bearing |
| **#16** | The v2 → main merge blockers, in order. `matewishkey-web#77` first, or their build goes red |

**And the one that is not filed because it is not a task: none of the three test scripts has ever been run in
its current form, and macOS has never had the kit installed on it.** Everything macOS in the table
above was measured by probing a real Mac; nothing was installed there. A red result on the first
real run is information, not a defect.
