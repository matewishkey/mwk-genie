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
| 7 | **`http://localhost:29292/` replaces the bookmark page** and the published learning artifact | See "The local site" below. |

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

`http://localhost:29292/` — **not** `mwk.local`. Measured reasons:

- `work.l` resolves because `.10` runs a LAN DNS server; a guest's laptop has none, and there is
  nothing to point a name at but their own machine.
- `.local` is reserved for mDNS, which is why this fleet picked `.l` instead. On this box
  `systemd-resolved` has mDNS **off** while `nsswitch.conf` routes `.local` to `mdns4_minimal`
  and `avahi-daemon` is running — a different resolution path entirely.
- Any name at all costs a sudo (`/etc/hosts`) or a daemon (mDNS). `localhost` costs nothing and
  behaves identically on macOS, Ubuntu and WSL.

Port `29292` verified free, and clear of `devproxy`'s 25000–25019.

**It replaces both keepers** — `templates/howto.html` and the published learning artifact. That
retires the worst failure mode in v1: the learning page's address had to be stored in three places
because a second published page is indistinguishable from a successful run. A directory has no
such problem. **Accepted cost: it is not reachable from their phone.** Mate's call — "from that
computer for now".
