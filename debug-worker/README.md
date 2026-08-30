# The debug sink

Runs in debug mode POST their log here so it does not have to be copied between machines.

**Nothing reaches it without a token.** A guest running the kit has no token and no
endpoint configured, so they upload nothing — that is enforced by the Worker returning
401, not by the client choosing to be quiet.

## Using it

```
MWK_DEBUG=<token> sh install.sh              # the installer ships its own log
MWK_DEBUG=<token> mwk-debug run -- mwk site  # run anything and ship what it printed
```

Read them back:

```
curl -H "Authorization: Bearer <token>" https://debug.matewishkey.com/          # list
curl -H "Authorization: Bearer <token>" https://debug.matewishkey.com/r/<run>   # one run
```

## What is in a log

The machine facts that matter for a bug — OS and version, WSL or not, shell, the kit's
commit, and which of the tools are on PATH — then the captured output.

**Anything key-shaped is replaced before it leaves the machine**: `$HOME` (so a username
cannot survive inside a path), age secret keys, `sk-`, `ghp_`/`gho_`/`ghu_`/`ghs_`/`ghr_`,
Slack tokens, JWTs, long base64 runs, and the debug token itself. Redaction happens on the
way out rather than by trusting the log not to contain one — the entire point of a debug
log is that it captured something you were not expecting.

Logs expire after 30 days. A debugging aid that accumulates forever becomes a thing to
worry about.

## First deploy

```
wrangler kv namespace create MWK_GENIE_DEBUG   # put the id in wrangler.toml
wrangler secret put MWK_DEBUG_TOKEN            # any long random string
wrangler deploy
```
