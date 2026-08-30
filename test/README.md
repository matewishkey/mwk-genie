# Tests

```
bash test/check.sh          # seconds, no Docker. Files, renders, URLs.
bash test/rehearse.sh v2    # minutes, Docker. The real install in a clean ubuntu:24.04.
```

**Pass a commit SHA to `rehearse.sh` right after a push**, not a branch name —
`raw.githubusercontent.com` serves a stale copy of a branch path for a few minutes, and
that has already cost two runs where the fix was in and the test was reading the old file.

`MANUAL.md` is the short list of what needs a browser, a login, or a person.

## The rule both scripts are written under

**When a check goes green, ask what would have to be true for it to go red.** If you cannot
construct that case, the check is decoration. v1's suite had three green ticks counting
nothing — a grep for a quoted string that never appears, a glob matching no directories,
and a `$()` that yielded `""` on a traceback and compared equal to `""`.

And: **a test that arranges its own preconditions is worse than no test.** `rehearse.sh`
pre-places nothing. If you find yourself adding a step to make it pass, the bug is in the
thing being tested.

## What is not covered, and cannot be

- **macOS.** Everything here runs on Linux or in a Linux container. The Mac path — Command
  Line Tools, iTerm2, no `timeout`, no pinentry — has no automated coverage at all.
- **The browser half.** Signing in, a paid plan, whether prompt one reads well to someone
  who has never done this.
- **Whether the agent behaves.** The scripts check what lands on disk. They cannot check
  that Claude reads the installer before running it, which is the guardrail prompt two is
  built around.
