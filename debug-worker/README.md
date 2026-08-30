# The debug drop box

`https://debug.matewishkey.com` — a Cloudflare Worker with a KV store.

**One way in, and it is not the way out.** Anyone running the kit with debug mode on can
POST a log; nobody can read one back without the token. That asymmetry is the whole point:
turning it on has to be one word a person can type while you are on a call with them, not
a token read down a phone line.

## Turning it on

```
MWK_DEBUG=1 sh install.sh              # the installer sends its own log
MWK_DEBUG=1 mwk-debug run -- mwk site  # run anything and send what it printed
```

It prints a short code at the end — `20260830-their-macbook-XZV4` — and tells them to read
it back to whoever is helping. The code carries the machine name, so with two testers you
can tell at a glance which is which.

**It is still off by default.** With `MWK_DEBUG` unset the client exits having sent nothing.
Somebody who never asks for help never uploads anything.

## Reading them

```
curl -H "Authorization: Bearer $TOKEN" https://debug.matewishkey.com/          # list
curl -H "Authorization: Bearer $TOKEN" https://debug.matewishkey.com/r/<code>  # one run
```

## What is in a log

The computer's **name**, its OS and version, WSL or not, the shell, the kit's commit, which
tools are on PATH — then the captured output.

The hostname is the one identifying thing, and it is there deliberately so two testers can
be told apart. **The client says so on screen before sending**, in plain words, rather than
letting someone find out afterwards what left their computer.

**Anything key-shaped is replaced before it leaves the machine**: `$HOME` first (so a
username cannot survive inside a path), age keys, `sk-`, `gh[pousr]_`, Slack tokens, JWTs
and long base64 runs. Redaction happens on the way out rather than by trusting the log not
to contain a key — the entire point of a debug log is that it caught something nobody
expected.

Logs expire after 30 days.

## Why open writing is safe here

Nothing is ever served back to the public, so a spammer gets no audience and no data. The
guards are about not paying for someone's fun:

| Guard | Measured against the live endpoint |
|---|---|
| Body must start with `=== mwk ` | a random `POST` → **400**, and no KV write to pay for |
| 512 KB cap | bigger → 413 |
| 20 posts per IP per hour | post 19 → 201, post 20 → **429** |
| Reads need the token | no token → **401** |
| 30-day expiry | logs are a debugging aid, not a record |

## Redeploying

The Worker is `mwk-genie-debug`, KV namespace `MWK_GENIE_DEBUG`, custom domain on the
`matewishkey.com` zone. `wrangler deploy` from this folder, or the REST API — the account
holds every project's workers, so the name prefix is what makes it findable later.
