# v2 — what was decided, and what was measured

Branch `v2`, opened 2026-08-28 off `db64756`. **Breaking changes are fine** (mate's call: there
are not many installs). This file is the record of *why*, so nothing here gets re-litigated from
memory. `CLAUDE.md` still describes v1 in most places — that rewrite is pending.

## Decided

| # | Decision | Why |
|---|---|---|
| 1 | **Not a plugin.** Skills install to `~/.claude/skills/mwk-*/SKILL.md` | No marketplace, no manifests, no three-names-must-agree rule, no `claude plugin install` step. Verified: `dotfiles-cz` installs `box-tidy` exactly this way and it loads. |
| 2 | **Prefix, not namespace.** `/mwk-save`, `/mwk-magic`, `/mwk-learning`, `/mwk-bug`, `/mwk-new` | User-level skills share one flat namespace, so the prefix goes in the directory name. Same readability, no plugin needed. |
| 3 | **chezmoi is the installer**, and it owns `~/.zshrc` from the first line ever written to it | Every documented near-miss in v1 was an agent interpreting prose slightly wrong. A marker-fenced region becomes a *file*; there is no append, so the whole class is gone. Half-owning a startup file is the one option worse than either extreme. |
| 4 | **Windows means WSL Ubuntu.** No native Windows target | `prompts/install.md` already says so, live on the site: *"There is a way to install the agent straight onto Windows… Do not take it."* A native target would share nothing with the Linux one and double the render matrix. |
| 5 | **Two questions**, in `.chezmoi.toml.tmpl` | `ccc_mode` and `admin`. The model question is gone — opus was already decided on 2026-08-11. |
| 6 | **No fleet anything.** No `~/.secrets`, no `td-sops`, no age recipients, no work.l | Mate will never run this himself; it is a clean install for clients, tested repeatedly on fresh machines. |
| 7 | **`http://localhost:29200/` replaces the bookmark page** and the published learning artifact | See "The local site" below. |

## The secret store — measured, 2026-08-28

Everything below was run on this box with `sops 3.13.3` and `age 1.1.1`. None of it is remembered.

### It works, and the shape follows from three measurements

1. **`sops` decrypts using a passphrase-protected age identity file.** `age -p` encrypts the
   identity; `SOPS_AGE_KEY_FILE=<that file> sops -d` prompts for the passphrase through pinentry
   and decrypts. Confirmed end to end against a dotenv fixture.
   *So the thing they save in their password manager is a password they were given — not a
   74-character `AGE-SECRET-KEY-1…` blob. That is the whole reason this shape was chosen.*

2. **pinentry needs a TTY, and an agent has none.** stdin is not a tty, stdout is not a tty, and
   `/dev/tty` cannot be opened at all. So `init`, `add` and `rekey` refuse in an agent's hands —
   enforcement, not a convention it has to remember.

3. **⚠️ gpg-agent caches the passphrase, so "locked" has a lifetime.** Default
   `default-cache-ttl` is **600s** (`max-cache-ttl` 7200s). Measured three-state, reproducible:

   | State | No-TTY decrypt |
   |---|---|
   | Cache flushed (`gpg-connect-agent reloadagent`) | **refused** |
   | Human unlocks at a real terminal | works, prompts once |
   | Immediately after, same command, still no TTY | **succeeds — the agent can read every value** |

   This is not a flaw to fix; it is what makes `mwk run` usable without building our own cache.
   But it means **`mwk lock` is the only thing that makes "locked" true**, and any claim that an
   agent structurally cannot read the values is false inside that window. Say so out loud.

### Two bugs found by testing, both of which would have shipped

- **`sops -e … > "$f"` truncates `$f` before sops runs**, so a failed encrypt *deletes the store*.
  Writes go to a temp file and get moved into place.
- **With a cold cache and no TTY, `sops -d` does not fail — it hangs** waiting on a pinentry that
  can never appear (measured: killed at a 2-minute timeout). Read commands therefore probe the
  lock state once, bounded, before touching a pipeline.

### Layout

```
~/projects/.mwk/
    identity.age              passphrase-encrypted age key — useless without the password
    identity.pub              the recipient. Plaintext, safe
    global.enc.env            global scope
    projects/<name>.enc.env   project scope
~/projects/my-site/
    .mwk-keys                 names + scopes, NEVER values. Safe to commit
```

**Ciphertext lives under `~/projects/.mwk/`, never inside a project folder.** A beginner will push
their project to GitHub, and ciphertext in git is permanent — including after the repo is made
public. The project keeps only the shopping list, which is also the thing that answers "what does
this project need?", which nothing could answer before.

**The key file is not next to nothing else that matters** — but note it *is* under the same
`~/projects` tree the person is told to back up. That is deliberate (one folder to save) and it is
exactly why the identity is passphrase-protected: a copied backup, or a stolen laptop, is useless
without the password.

### Still to build

- `mwk redact` — the stream filter, sourced from the same store (names *and* values; a redactor
  needs plaintext to match on). It must **fail loudly when the store is locked**: a silent no-op
  redactor is worse than none, because it looks like it is working.
- The value most worth masking is the **master password and the identity file itself**.
- Show-safety: `mwk rekey` exists so that a password that went out on stream is a ten-second fix
  rather than a disaster. That is the honest answer, not a promise that it cannot happen.

## The local site

`http://localhost:29200/` — **not** `mwk.local`. Measured reasons:

- `work.l` resolves because `.10` runs a LAN DNS server; a guest's laptop has none, and there is
  nothing to point a name at but their own machine.
- `.local` is reserved for mDNS, which is why this fleet picked `.l` instead. On this box
  `systemd-resolved` has mDNS **off** while `nsswitch.conf` routes `.local` to `mdns4_minimal`
  and `avahi-daemon` is running — a different resolution path entirely.
- Any name at all costs a sudo (`/etc/hosts`) or a daemon (mDNS). `localhost` costs nothing and
  behaves identically on macOS, Ubuntu and WSL.

Port `29200` verified free, and clear of `devproxy`'s 25000–25019.

**It replaces both keepers** — `templates/howto.html` and the published learning artifact. That
retires the worst failure mode in v1: the learning page's address had to be stored in three places
because a second published page is indistinguishable from a successful run. A directory has no
such problem. **Accepted cost: it is not reachable from their phone.** Mate's call — "from that
computer for now".

## One package manager — the answer is none (measured 2026-08-30)

The question was Homebrew-on-the-Mac plus apt-on-Ubuntu versus something single. The kit needs
exactly four tools plus language runtimes, and **all four are single binaries their own projects
publish for both platforms**. So no package manager is required at all — `mise` reads one
`mise.toml` and fetches the right binary per platform.

Three of mise's backends were tried, and only one is right:

| Backend | Result |
|---|---|
| `ubi:` | **Deprecated.** mise prints it on use: *"Use the github backend instead … This will be removed in mise 2027.1.0."* It also installs only ONE executable, so `age` arrived without `age-keygen` — which `mwk init` needs. |
| `github:` | Extracts the whole archive, so `age-keygen` comes along. But it exposes whatever the asset is **named**, and sops publishes a bare `sops-v3.13.3.linux.amd64` — so no `sops` command appears at all. |
| `aqua:` | ✅ The curated registry knows each project's naming: `sops`, `age`, `age-keygen`, `miniserve` all land under the right names. It also **verifies SLSA provenance** on the way in, which neither brew nor apt was doing. |

Versions are **pinned** and `mise.lock` is committed. "latest" would mean two people running the
kit a month apart get different binaries, and every upgrade would be invisible rather than a
reviewable diff.

**Homebrew's only remaining case was iTerm2, and iTerm2 is optional** — `Ctrl+J` makes a new line
in every terminal including Apple's. If it is ever wanted,
`iterm2.com/downloads/stable/latest` 302s straight to a versioned `.zip`. Verified.

### chezmoi's prompts need a TTY

`chezmoi init` fails with *"could not open a new TTY: open /dev/tty"* when there isn't one. So
**an agent cannot run `install.sh`** any more than it can run `mwk add`. That is the design mate
asked for — the person runs the script, the agent does the work afterwards — and it is now
enforced by the tool rather than by an instruction.

For unattended runs (the rehearsal) only `--promptDefaults` works; `--promptChoice ccc_mode=…`
does **not** satisfy `promptChoiceOnce` in chezmoi 2.72.0 — tried, it still prompts. Consequence:
the automated test only ever exercises the **fast** path. Testing **careful** needs a real
terminal, so it belongs in `test/MANUAL.md`.
