# Testing the kit

Every URL, command name and shell line in this repo is handed to a stranger whose agent will
act on it. Two scripts check what a script can.

```
bash test/check.sh      # seconds, no Docker
bash test/rehearse.sh   # minutes, needs Docker, pulls ubuntu:24.04
```

Both print a pass/fail line per check and exit non-zero if anything failed. **Run both before
pushing** — `check.sh` always, `rehearse.sh` whenever you touch `SETUP.md`, the templates, or
the plugin.

## `check.sh` — the things that broke before

- `claude plugin validate`, and the bit **validate does not do**: that `SETUP.md` quotes the
  marketplace and plugin names correctly. That broke once, at the rename.
- Both manifests agree on the version, and on the plugin's name.
- Every skill has matching frontmatter, is named in `SETUP.md`, in `howto.html`, and in the
  marketplace description — so a new command cannot ship undocumented.
- The written-out command count (`five commands`) matches how many skills exist.
- `bash -n` **and** `zsh -n` on both shell templates, then **sourcing them in both shells** —
  `prompt.sh` branches on `$ZSH_VERSION`, so passing a syntax check proves nothing.
- `ccc.sh` has exactly one live alias and one commented alternative, and moving the `#` really
  does give the other one. That swap is the instruction printed on the how-to page.
- `__mwk_git` prints ` (branch)`, ` (branch*)` when there is unsaved work, and nothing outside
  a repo.
- The pasted prompt in `prompts/setup.md` fits 60 columns. The website's build asserts this and
  **fails** rather than publishing a wide line, so a long line here breaks somebody else's build.
- **The bookmark page** (`templates/howto.html`) — every command block has a copy button and no
  block is empty, the copy has both a clipboard-API path and an `execCommand` fallback, no stylesheet, script,
  font or image is loaded from another host (an artifact's CSP would drop it — the check flags every
  absolute `src` and every fetching `<link>`, so a query string no longer hides one, but a
  `fetch()` in script would still slip through), the design tokens are all
  defined, dark theme covers both `prefers-color-scheme` and an explicit `data-theme`, **the copy
  buttons are not red** in *any* of their rules — a red `:hover` used to slip past a check that read
  only the first one — and **the inlined block's
  path data matches the live `favicon.svg`** — so a hand-built red square, or the site redrawing
  the mark, both surface here. (It compares the `d="…"` attributes, not the whole file, so a
  colour or `viewBox` change would slip through. If the site is unreachable this check **skips**,
  and a skip is reported separately from the passes — it is not a pass.)
- **The shell templates install cleanly and only once** — both files are fenced by
  `# >>> mwk-genie:<name> >>>` markers so `SETUP.md` replaces rather than appends. The check
  installs `ccc.sh` twice the documented way, then performs the `#` swap the bookmark page tells
  people to make, and asserts the shell ends up with the alias they *asked* for. It also asserts
  `SETUP.md` still carries both halves of that instruction, that `ccc.sh` puts `~/.local/bin` on
  `PATH` without stacking duplicates, that appending to a file with no trailing newline still
  sources, that `prompt.sh` survives `set -u`, and that the **rendered** prompt contains the branch
  — not just that `__mwk_git` returns one, which stayed green with `PROMPT_SUBST` deleted.
- **The learning skill keeps its three ways home** — the pinned artifact title, the instruction to
  hand the stored address to the publish step, both stored copies, the refusal to guess when they
  are gone, the ordered recovery list itself, and its copy of the three design rules. That page is
  *generated*, so no file here is the page and nothing can diff it; asserting the skill's own text
  is the most that can be done.
- **`Ctrl+J` is offered and `/terminal-setup` is not** — the second does not configure Apple's
  Terminal, and saying it does sends the person who declined the install away believing it is fixed.
- **The published prompt fences carry no em or en dashes** — the site fails its build on dashes in
  rendered text but exempts `<pre>`, which is what these become, so the guard lives here.
- Every URL handed to a stranger returns 200 **and is the address that answers, not one that
  forwards**. The list is **extracted from the files that ship** — `SETUP.md`, both prompts, the
  README, the templates, the skills, the issue forms — and whatever it finds is curled. It is not
  enumerated here or in the script, because a hand-kept list checks the URLs somebody remembered to
  add, which is not the same set as the URLs a stranger is handed; breaking a real link in two
  shipped files used to leave this section fully green. Plus the Homebrew cask `iterm2` against
  Homebrew's own API, and a check that the Anthropic plugins named in `SETUP.md` still exist in that
  catalogue — that list is derived from `SETUP.md` too, after the hardcoded version turned out to
  pass for a plugin name that does not exist.

  **A 301 is a failure here.** It works until somebody re-uses the old path, which is exactly how
  the repo rename and `/wishes/put-the-genie-in-the-box` both went. Three URLs redirect by design
  — the GitHub tarball to codeload, the issue form to a login wall when signed out, and
  `claude.ai/install.sh` to `downloads.claude.ai` — and are marked `redirects-ok`, because a
  stable name in front of a CDN is the whole point of that name.

## `rehearse.sh` — does it work on a machine that is not this one

A clean `ubuntu:24.04`, a normal non-root user, and deliberately **no `git` and no `curl`** to
begin with, because that is the machine `SETUP.md` warns about.

- **A — stage zero, against published `main`.** Confirms the bare image really is missing both
  tools, then does the `curl` + `tar` download and the `git clone` download exactly as written.
- **B — stage one, against your working tree.** Appends the two templates to `.bashrc`, then
  opens a **genuinely fresh interactive shell** and runs `ccc`. A stub `claude` on `PATH` reports
  how it was called, so this proves the flag actually arrives — *`ccc` existing is not the same
  as `ccc` starting the agent the right way, and that difference is invisible to a beginner.*
  It is what failed on show 001. Also swaps the `#` and checks the other variant, and checks the
  prompt's star on a throwaway project.
- **C — stage two, with real Claude Code**, installed by its own installer, no package manager.
  Adds the marketplace, installs the plugin, and confirms the version and every skill. Then
  merges `"model"` into the `settings.json` the plugin just wrote and confirms the plugin
  survives — which is what step 10's warning is about.

**Phase A tests `main`, phases B and C test your working tree.** So A can pass while your
uncommitted changes are broken; B and C are the ones that test what you are about to push.

> **Never run git commands against the container's copy of the kit.** Your changes are
> uncommitted, so a stray `stash` or `checkout` silently reverts it to published `main` and the
> run then tests the wrong thing. This already happened once while writing these scripts; the
> version assertion in phase A exists to catch it.

## What neither script covers

See [`MANUAL.md`](MANUAL.md). Short version: anything needing a browser, a login, or a human
looking at something.
