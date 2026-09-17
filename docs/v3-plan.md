# v3 — the cut, and why

Decided with mate on 2026-09-17. This is the plan; `CLAUDE.md` stays the current picture and gets
rewritten as the work lands. **Not started** — nothing below is true of the code yet.

## The rule that drives every line of this

**A command exists only if it is needed OFTEN. Everything infrequent, the agent does.** It is on
the machine, it can see the actual state, and it will deal with a one-off better than a function
written months earlier for a machine nobody had seen. So: no `restore`, no `rekey`, no `init`, no
`list`, no menu. A function around something rare is a function that rots.

The floor stays a script. `install.sh` runs before the agent is useful, is read before it runs
(`prompts/setup.md`'s four questions), and is tested in a container. OpenClaw's own install is
`curl … | bash` too, and their docs say a skill "cannot install or update the runtime itself" —
the shape we have is the shape they have. That was checked, not assumed (2026-09-17).

**Fix the silent bugs, let the agent handle the loud ones.** The agent routes around a missing
tool or a 404. It does not route around `Stored ✓` printed over a store that just lost two keys.

## The store: `~/projects/keys`, a private repo, plain age key

Measured 2026-09-17, `sops 3.13.3` + `age 1.1.1`, under `env -i` (this box's fleet shell exports
`SOPS_AGE_KEY_FILE` and contaminated the first run — the kit never sets it, a stranger's machine
never has it, but **run store research in a clean env**):

| step | result |
|---|---|
| `age-keygen -o ~/.config/sops/age/keys.txt`, no env var | sops finds it there on its own — that is its default path |
| `.sops.yaml` with one `path_regex: \.enc\.env$` rule and **no catch-all** | a file matching nothing fails loudly: `no matching creation rules found` |
| encrypt a dotenv | recipient == our key, no plaintext in the file |
| decrypt with the key hidden (**negative control**) | exit 128, `Failed to get the data key` — the key is genuinely what protects it |
| `sops exec-env file 'cmd'` | the child sees the variable; no plaintext ever touches disk |
| new key → `sops updatekeys -y` | old key exit 128, new key decrypts. **Rekey is one command; it needs no `mwk rekey`** |
| `git add -A` | `.sops.yaml` + ciphertext staged, **zero `AGE-SECRET-KEY` lines** |

```
~/projects/keys/                private GitHub repo — visible, backed up, clonable on a new machine
  .sops.yaml                    their PUBLIC key. Safe to commit, safe to serve
  global.enc.env                keys every project can use
  projects/<name>.enc.env       one per project, created the first time that project needs one
~/.config/sops/age/keys.txt     the PRIVATE key. 600, outside ~/projects, never in git
```

**What they save once:** the `AGE-SECRET-KEY-1…` line, in their password manager. A 74-character
string is what password managers are for. The passphrase layer existed to turn that into "a
password" and it cost pinentry, gpg-agent, the 600s cache, the TTY refusals, `lock`, `rekey`, and
the Mac-behaves-differently fork. Gone with it.

**How they see it once, without it ever entering a transcript:** the agent tells them, in chat,
to open a second terminal and type `cat ~/.config/sops/age/keys.txt`. Not a command of ours. The
agent never runs that line itself — that is a rule in `create_CLAUDE.md`, not a mechanism.

**Ciphertext under `~/projects` is fine.** The old reason for `~/.mwk` living outside the served
root was that miniserve follows symlinks and `GET /store/identity.age` returned 200 from the LAN.
That was the *encrypted identity* — the thing the passphrase protected. Now nothing under
`~/projects` is secret; the one secret file is at the sops default path and is not served by
anything. (And miniserve is leaving anyway — below.)

## `mwk` after the cut: four commands, ~150 lines

| keep | why it survives the rule |
|---|---|
| `mwk add NAME [project]` | **The one thing that structurally needs a human at a keyboard.** The value is read at a hidden prompt so it never passes through chat, argv, `ps` or history. Self-initialising: no store → keygen, `.sops.yaml`, `git init`, then "now save your key". `init` disappears into it |
| `mwk run -- cmd` | Frequent, and used by the agent every time a project runs with keys. `sops exec-env` twice (global, then project) — thin, but typed constantly |
| `mwk update` | The one that must work when the agent's own instructions are stale. Six lines delegating to `install.sh` |
| `mwk uninstall` | Five lines delegating to `uninstall.sh`. Not frequent — kept because it is the escape hatch when the agent is the broken thing. **Mate's call** |

| cut | the agent does it instead |
|---|---|
| `init` | folded into the first `add` |
| `list` | `sops -d … \| cut -d= -f1` |
| `needs` | writes a file |
| `lock`, `rekey` | no passphrase; `sops updatekeys` after a new key |
| `site`, `serve`, `port`, `queue`, `files` | **the page is going** (below); serving a folder is `miniserve -p 292xx dir` or `python3 -m http.server`; browsing files is `open .` / `explorer.exe .` |
| the menu | four commands do not need a menu. `mwk` alone prints usage |
| `mwk-debug` + the Cloudflare worker | 172 lines and a deployed service for "see a stranger's failed install". The agent on their machine reads the output and files it with `/mwk-bug`. **Mate's call** — he asked for it in August |

## The page is going

`mwk/site/` (375 lines), `queue.json`, `projects.json`, `ports.tsv`, the 292xx scheme, `password.html`,
and **miniserve out of `mise.toml`** (six tools → five).

The page had one job: show the person a command they must run themselves. Its customers after
the cut are `mwk add` and the once-only `cat keys.txt`. Both are a sentence in chat — and
`CLAUDE.md` already records that every queued command was printed in chat too, "because a page
that is not running is nothing at all". A duplicate of chat is not worth 375 lines and a server.

`/mwk-learn` wrote to `mwk/site/learnt.html`. It now writes `~/projects/learning/README.md` —
git-backed, renders on GitHub, and it is in `~/projects` where mate wants everything.

## Skills after the cut

| | |
|---|---|
| `mwk-new` | keep. Does **not** pre-create a keys file; the first `mwk add NAME project` does |
| `mwk-save` | keep. Gains the "finished for good?" branch — tend the repo's issues, then push — so **`mwk-close` is a paragraph here, not a skill**. Closing a project is rare. **Mate's call** |
| `mwk-review` | keep as is |
| `mwk-learn` | keep, retargeted to `~/projects/learning/README.md` |
| `mwk-bug` | keep |
| `mwk-tasks` | **add.** `gh` straight from the skill, inbound + outbound, `**From:**` markers — `/td-fly:mailbox` for one person. No `tasks.json`, no page section |
| each skill | gains a `requires:` line naming the binaries it calls, and `check.sh` asserts every one is in `mise.toml`. `mwk-save` was written needing `gh` and nothing installed it — that class closes |

`create_CLAUDE.md` gains a keys section: where the store is, `mwk add` is theirs not yours, `mwk run`
wraps, never `cat keys.txt`, and the once-only line to hand them. Plus the three things the agent
now handles with no function at all — a new machine (`paste the key, clone keys, clone the rest`),
a rekey, serving a folder — each as one sentence, not a procedure.

## What this deletes from `CLAUDE.md`'s measured-facts table

Rows about pinentry, gpg-agent, the cache window, `SOPS_AGE_KEY` + `SOPS_AGE_KEY_FILE` re-opening
the identity, `[ -t 1 ]` vs `/dev/tty`, `exit` inside a pipeline (that was `sops_d`), miniserve's
symlinks and missing `--allowed-hosts`, `127.0.0.1` not stopping a web page, the `mwk add`
ate-the-store mechanism. Every one is a fact about a component that is leaving. The `grep -c`,
`python3`, xcode-shim and `.chezmoiignore` rows stay — those are about the floor.

## Order of work

1. **The store.** Rewrite `add` + `run` on the plain key; `test/check.sh` runs `mwk add` against a
   real scratch store under `env -i` and reads every previous name back — the check that was
   confirmed red against the bug that ate the store stays, on the new code.
2. **Delete** `lock`, `rekey`, `init`, `list`, `needs`, the menu.
3. **Delete the page** and everything that fed it; miniserve out of `mise.toml`; `.chezmoiignore`
   and `rehearse.sh`'s placed-file list updated **and asserted by name in both directions**.
4. `mwk-learn` → `~/projects/learning/`. `mwk-tasks` written. `mwk-save` gains the closing branch.
5. `create_CLAUDE.md` keys section + the no-function sentences. `requires:` on every skill.
6. `rehearse.sh` green against the pushed SHA. `CLAUDE.md` rewritten to describe what is there.

## Open — mate decides, then it is not re-argued

| | recommendation |
|---|---|
| Name of the repo | `keys`. `mwk-sops` matches the fleet and means nothing to the person looking for it in a panic |
| `mwk uninstall` | keep (escape hatch) |
| debug worker | cut; `/mwk-bug` is the channel |
| `mwk-close` | a branch of `mwk-save`, not a sixth skill |
