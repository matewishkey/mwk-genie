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

## How v3 works, in one pass

```
prompt one  (browser)  → Mac or Windows? → WSL / Xcode CLT → Claude Code → start it with
                         --dangerously-skip-permissions
prompt two  (Claude)   → read install.sh and report → run it → prove it → a folder to work in
install.sh             → kit → mise → 5 pinned tools → Claude Code → mise use -g → chezmoi apply
chezmoi                → ~/.mwk-shell.sh, ~/bin/mwk, ~/.claude/{CLAUDE.md,settings.json,skills/},
                         and on macOS iTerm2
mwk                    → add · run · update. That is all of it.
```

**It is not a plugin.** Skills are placed straight at `~/.claude/skills/mwk-*/SKILL.md`, which
loads with no marketplace and no manifest. The prefix is in the directory name because user-level
skills share one flat namespace.

## The rule that shapes v3 (mate, 2026-09-17)

**A command exists only if it is needed OFTEN. Everything infrequent, the agent does.** It is on the
machine, it can see the actual state, and it will handle a one-off better than a function written
months earlier for a machine nobody had seen. So there is no `init`, `list`, `needs`, `lock`,
`rekey`, `uninstall`, `restore`, no menu, no page. `create_CLAUDE.md` carries each of those as one
sentence under *Things that need no command*. **Don't add a command for something rare.** It rots.

**The floor stays a script.** `install.sh` runs before the agent is useful, is read before it runs,
and is tested in a container. OpenClaw's own install is `curl … | bash` and their docs say a skill
"cannot install or update the runtime itself" — checked 2026-09-17, not assumed. v1 was an agent
following prose for ~30 steps, and every documented near-miss came out of that.

**Fix the silent bugs; let the agent handle the loud ones.** It routes around a missing tool or a
404. It does not route around `Stored ✓` printed over a store that just lost two keys.

`docs/v3-plan.md` is the record of why, with the research table and the four decisions.

## The one question, and the two that were deleted

`.chezmoi.toml.tmpl` prompts for **nothing**. The single question — Mac or Windows — lives in
`prompts/install.md`, because Windows needs WSL before a terminal exists and nothing later can ask.

**Removing the prompts removed a TTY requirement**: chezmoi needed a terminal only because it was
asking; with nothing to ask, an agent can run `install.sh`, and the 87-character one-liner never
has to appear inside a prompt file.

- **Model** — deleted. Opus, settled 2026-08-11. Written by `dot_claude/modify_settings.json`;
  removing the question once removed the setting with it — Claude Code's own default is not opus.
- **Admin** — deleted, not answered. iTerm2 goes to `~/Applications`, which needs no password, so
  nothing in the flow uses `sudo` at all.
- **`ccc_mode`** — decided for them, in `.chezmoidata.yaml`, as `fast`. Mate's call, 2026-08-30.
  The escape hatch is one character: `~/.mwk-shell.sh` ships both alias lines with one commented
  out. **If that escape hatch ever stops shipping, the argument has to reopen.**

## The read-before-you-run guardrail

`prompts/setup.md` makes the agent read `install.sh` and answer four questions out loud: sudo,
writes outside `$HOME`, unexpected download hosts, deletions. A stranger cannot read it themselves,
and "trust us" is not an answer.

**The checklist must stay true of the script.** It once listed three hosts while `install.sh`
fetched from four, so the guardrail would have fired on its own installer. **A guardrail that cries
wolf the first time is ignored the second.** `check.sh` now extracts every host `install.sh` fetches
from and asserts `setup.md` names each one.

## Things measured on real machines, so nobody re-derives them

| Fact | Consequence |
|---|---|
| `/usr/bin/git` and `/usr/bin/clang` share an inode on macOS — it is the xcode-select shim | `command -v git` is true with no dev tools. Ask `xcode-select -p`, not whether a file exists |
| macOS has **no `timeout`** and no `gtimeout` | Calling it exits 127. Nothing in v3 calls it; if something ever does, this is why it dies on a Mac |
| A stock Mac has **no pinentry and no gpg-agent** | Irrelevant since 2026-09-17 — the passphrase is gone. Kept because it is why the passphrase is gone: it made `mwk lock` mean two different things on two platforms |
| Binaries fetched by curl/Go carry `com.apple.provenance`, not `com.apple.quarantine` | Gatekeeper does not block the toolchain. **Never add a blanket `xattr -dr`** to "fix" it |
| chezmoi, sops and age were checked ad-hoc signed arm64; jq and gh were pinned later and not re-checked | They exec on Apple Silicon. `spctl -a` says "rejected" for ad-hoc binaries — that is the assessment API, not exec enforcement |
| `mise` shims resolve from the config **in scope** | `mise.toml` is a project config, so tools were active only inside the kit. `mise use -g` fixes it |
| A plain chezmoi-managed `settings.json` | With no TTY it **aborts the whole apply**; with `--force` it reverts the file and destroys `enabledPlugins`. Use `modify_`; `.chezmoi.stdin` does not exist, so it must be a script. **Measured to preserve `enabledPlugins`, 2026-09-13** — it was an assumption until the fixture was proved planted |
| `.chezmoiignore` patterns match the **target** name | `dot_claude/**` matches nothing — the target is `.claude/**`. Writing the source name places NOTHING while reading correctly |
| `A && B \|\| C && D` groups as `((A && B) \|\| C) && D` | A successful first branch still ran the second. Use `if/elif` |
| `[ -t 1 ]` is false inside **every** pipeline and every `$()` | It asks about the current redirection, not whether a person is there. `have_tty` asks whether `/dev/tty` **opens** |
| `exit` from a pipeline stage leaves the **subshell**, not the script | A function that reads must `return` non-zero and let the main shell decide. This is how `mwk add` once replaced the store with one key |
| **`grep -c` exits 1 when the count is zero** | `n=$(grep -c x f \|\| echo 0)` yields the two-line string `0\n0`. Use `\|\| true` and default only the empty case |
| `ubuntu:24.04` ships **no python3** | A `python3 … \|\| true` fixture plants nothing and the check never runs. **Assert the fixture landed before asserting what survives it** |
| `env -i … <shell function>` is "No such file", silently | `env` execs binaries. The store test's first run reported "no store was made" against a store that was. Put the pty inside the env, not a function around it |
| **sops searches for `.sops.yaml` upward from the CURRENT DIRECTORY** | `mwk add` runs from inside a project, not the store. Pass `--config` explicitly |
| **sops matches creation rules on the file NAME, and stdin has none** | `--filename-override <name>`, or a no-catch-all `.sops.yaml` refuses with `no matching creation rules found` — which is that rule doing its job on the wrong file |
| **A login shell has `~/bin` but not mise's shims.** Ubuntu's `.profile:20-21` adds `~/bin`; `.bashrc:6-8` returns before the kit's source line whenever the shell is non-interactive (`su - user -c`, cron, a script) | Measured in `ubuntu:24.04`, 2026-09-17. So `mwk` is found and `sops` is not. A tool preflight at the top of `mwk` made bare usage exit 1 and would have killed `mwk update` — the command for when things are broken. Tools are checked inside `add` and `run` only. **Same class, second time:** `statusline.sh` was placed, wired, and printed nothing under a login shell — `jq` is a shim too, and Claude Code inherits PATH from whatever launched it. The script names the shim path itself now |
| This box's fleet shell exports `SOPS_AGE_KEY_FILE` | It contaminated the first round of store research with an unexplained recipient mismatch. `mwk` sets it explicitly; `check.sh` runs the store under `env -i`. **Do store research in a clean env** |
| `api.github.com` sends `access-control-allow-origin: *`, but a **private** repo 404s unauthenticated | Measured with a positive control (`td-sops` private → 404, `mwk-genie` public → 200). It decided that no page would ever read their issues — and then the page went anyway |

## The store — `~/projects/keys`

A private git repo of sops-encrypted dotenv files, and **one plain age key at sops's default path,
`~/.config/sops/age/keys.txt`**, mode 600. The thing they save in their password manager, once, is
that key's `AGE-SECRET-KEY` line.

```
~/projects/keys/.sops.yaml          their PUBLIC key, one rule, no catch-all. Safe to commit
~/projects/keys/global.enc.env      keys every project can use
~/projects/keys/projects/<slug>.enc.env
~/.config/sops/age/keys.txt         the PRIVATE key. Never in git, never in ~/projects, never in chat
```

Measured 2026-09-17 under `env -i`, sops 3.13.3 / age 1.1.1 — the table is in `docs/v3-plan.md`:
sops finds the default key path unaided; a hidden key fails instantly (exit 128 — the hang was
pinentry, and pinentry is gone); `sops updatekeys -y` after a new key locks the old one out; `git
add -A` stages zero secret lines.

**What replaced what.** `~/.mwk` with a passphrase-encrypted identity was chosen so the saved
thing was "a password"; it cost pinentry, gpg-agent, the 600s cache, three TTY refusals, `lock`,
`rekey`, and a per-platform fork — and it had **no backup**. A 74-character string is what
password managers are for, and a repo is what backups are for.

**Three things are load-bearing in `bin/executable_mwk`, and `check.sh` asserts each:**

- **`add` refuses without a TTY**, using the property that was measured (`/dev/tty` opens), and has
  **no `--value` flag** — that removes argv, `ps` and shell history as a class.
- **A store with no key is a NEW COMPUTER, not a first run.** `ensure_store` refuses to mint a key
  when `.sops.yaml` exists; a fresh key there would encrypt the next add to a key that cannot read
  the rest of the repo, and it would look like it worked. It says where the saved key goes.
- **`add` reads before it prompts, dies on a failed read, keeps the old ciphertext until the new one
  is proved, and reads the store back to confirm every previous name survived.** That is the
  2026-08-30 bug's fix, carried over. `check.sh` runs it against a real scratch store through a
  pty, and was confirmed red with the merge sabotaged before being trusted green.

Each `add` commits in the store. Pushing is `/mwk-save`'s — that needs GitHub, a commit needs nothing.

## The failure this repo keeps having

**A string replace that does not match is silent, and it looks exactly like one that worked.**
v1's green ticks counted nothing; an ignore file placed nothing while reading correctly; a menu
renumbering left two number 3s; `mwk add` replaced the store with one key while printing `Stored`;
a test fixture that never ran reported a verdict anyway; a `pty` function behind `env -i` never
executed and the suite said the store was never made.

Every one was written confidently and reviewed as correct. The defence is not more care, it is
asserting the result: after an edit, read back the thing that should have changed, and **when a
check goes green, break the thing and watch it go red first.** `check.sh` asserts the placed-file
list by name in both directions, the promised skill names against the shipped ones in both
directions, the dispatcher's arms against the usage text, and every cut command against every
document that ships.

## The cross-repo coupling — editing a prompt here changes the live website

**`mergodon/matewishkey-web` FETCHES `prompts/install.md` and `prompts/setup.md` AT BUILD TIME**
(`src/data/genie-prompts.ts`) and renders them at **`matewishkey.com/wishes/put-the-genie-in-the-box/`**.
The `/how-to/` path 301s **to** `/wishes/`, not the reverse.

- It reads the **first** fenced block. A second fence above it publishes the wrong thing.
- It **caps `prompts/setup.md` at 60 columns and throws.** v2 unwrapped them (longest line 445), so
  **matewishkey-web#77 must land before merging** or their build goes red. Still open, 2026-09-17.
- A missing prompt file does **not** fail — it serves a stale cached copy with a warning. Green and
  wrong is worse than red.

**The third coupling is hand-typed and nothing checks it.** `src/content/wishes/put-the-genie-in-the-box.mdx`
quotes the opening of what is now `dot_claude/create_CLAUDE.md`, and the prose around it says "two
prompts", "three stages", "it asks you three things" and "an `mwk` plugin" — all false. Filed in #77.

## Rules that survived and still apply

**Verify identifiers.** Every URL here is handed to a stranger whose agent acts on it. `check.sh`
extracts URLs from the files that ship and curls them; it does not read a hand-kept list.

**A test that arranges its own preconditions is worse than no test.** When a check goes green, ask
what would have to be true for it to go red.

**Existing is not running.** `test -x ~/bin/mwk` passed for a day while `~/bin` was on nobody's
PATH and the first command a person is told to type did not exist.

**The show is mentioned twice, and no more** — it currently has **one** home, `README.md:7`.
Unresolved, and mate's to decide (#14).

**No disclaimer link.** Settled 2026-08-09 and still settled.

**One kit, not one per platform** (mate, 2026-09-13, after measuring). WSL Ubuntu *is* Linux —
`uname -s` says `Linux` — and the whole kit branches on OS in three places: the xcode-select shim
check and the Darwin|Linux gate in `install.sh`, and `run_onchange_after_20-darwin-iterm2.sh.tmpl`.
Forking would duplicate ~1000 lines to manage three conditionals. The two platform differences that
were real — the passphrase cache and the served page — are both gone with v3.

## Test it before you push

```
bash test/check.sh                    # seconds, no Docker. Runs mwk add against a real scratch store
bash test/rehearse.sh <sha>           # minutes, Docker, install → update → uninstall → reinstall
curl … test/on-this-machine.sh | sh   # a REAL machine. See test/README.md
```

Pass a **commit SHA**, not a branch — `raw.githubusercontent.com` serves a stale branch for minutes
after a push, and that has already cost two runs.

**Run, 2026-09-17, against `eae3104`: `check.sh` 154/154, `rehearse.sh` ALL GREEN (34 assertions).**
The container run before it, against `f3c6400`, found one real bug — a tool preflight at the top of
`mwk` that killed usage and would have killed `update` under a login shell (the table has the row).

`check.sh` needs `sops`, `age-keygen` and a working `script(1)` for the store test, and says
**SKIPPED — not a pass** when it cannot run it. `on-this-machine.sh` has still never been run, and
macOS has still never had the kit installed on it — everything macOS in the table above was
measured by probing a real Mac. A red result on the first real run is information, not a defect.

## v3.1 — the warm environment (mate, 2026-09-17, second round)

What v1 had that v2/v3 had lost, brought back without a page or a new command:

- **No `ccc`. They type `claude`; auto mode is `permissions.defaultMode: "auto"` in
  `settings.json`**, set by `modify_settings.json` only if absent — so a value they change
  stays changed, and that is the escape hatch. `claude 2.1.274` has `--permission-mode auto`
  (measured); the docs describe it as a classifier approving each action in the background,
  versus `bypassPermissions` skipping every check including protected paths. **The one
  unmeasured thing: the docs say "when auto mode is available to your session".** What
  `--permission-mode auto` does on an account that lacks it is unknown from this box;
  `on-this-machine.sh` asks it on a real account. Mate uses auto himself and prefers it.
- **The status bar** — `~/.claude/statusline.sh`, wired by the same merge. Model, folder,
  `% full`, red past 70. Fields verified against the docs (`model.display_name`,
  `workspace.current_dir`, `context_window.used_percentage`, null before the first reply).
  Cost: a custom status line hides most of the footer hints (`esc to interrupt`, `?`); the
  howto teaches the two that matter.
- **The howto is the top half of `~/projects/learning/README.md`**, placed by chezmoi as a
  `create_` file — **write-once, ours on day one, theirs after** — and `mwk-learn` writes
  under its `## What I have learnt` heading and never above it. `rehearse.sh` appends a
  line to it and asserts the line survives an apply. v1's `howto.html` sections, in
  markdown, with `claude` and the store as they are now. **It is the second of the two show
  mentions**, and `check.sh` counts exactly two across it and `README.md`.
- **`/mwk-onboard`** — GitHub, Cloudflare, Replicate; keys in via `mwk add … global` from a
  second tab; each proved with a real call. Endpoints measured 2026-09-17:
  `api.cloudflare.com/client/v4/user/tokens/verify` 200 good / 400 bad,
  `api.replicate.com/v1/account` 200 / 401. `setup.md` hands to it. Dashboard click-paths
  are deliberately NOT in the skill — it points at each vendor's current docs.
- **The page rule + `site-templates/report/index.html`.** Anything longer than a screen
  is a page (artifact), the chat keeps the one-line answer; **pages communicate,
  `~/projects` keeps** — the distinction that made `mwk-learn` drop artifacts as a *record*
  still holds. Everything is inline in the template because an artifact cannot load a
  file beside it. Unverified: artifact publishing on a stranger's claude.ai tier.
- **The house rule** — `input/`, `archive/<date>/`, one-line `README.md`, `TODO.md`,
  `input/`+`archive/` gitignored — built by `/mwk-new` (it made only a `README.md` before;
  that was #13's unbuilt half) and stated in `create_CLAUDE.md`.
- **Rejected: keeping learnings inside `~/projects/mwk-genie` gitignored, or in a
  dotfolder.** Gitignored = no backup, which is the whole point; inside the kit = `mwk
  update` pulls over it and uninstall trashes the folder with it; a dotfolder breaks
  "everything visible in `~/projects`". A repo of their own is the only shape that survives.

## Still open

| # | |
|---|---|
| **#13** | `mwk` menu option 1 was a stub. **The menu is gone — close it** |
| **#14** | The show is mentioned once and the rule is exactly two. A decision about tone |
| **#15** | Caddy as the shared front for project sites. **Nothing serves any more — close it** |
| **#16** | The v2 → main merge blockers, in order. `matewishkey-web#77` first, or their build goes red |
