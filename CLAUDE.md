# mwk-genie — agent notes

The starter kit for **[Mate Wish Key](https://matewishkey.com)**: an AI agent running on somebody's
own computer, set up for a person who has never opened a terminal. Two prompts they paste, and a
`SETUP.md` the agent works through. `README.md` is the front door for a human; this file is the stuff
that will bite you.

**THERE ARE TWO `CLAUDE.md` FILES IN THIS REPO AND THEY HAVE NOTHING TO DO WITH EACH OTHER.** This
one is notes for whoever works ON the kit. `templates/CLAUDE.md` is a **product artefact** — it gets
copied to a stranger's `~/.claude/CLAUDE.md` and becomes the rules their agent lives by. Editing the
wrong one is silent: the build does not fail, nobody notices, and either the kit stops working or a
beginner gets instructions meant for you.

## The order is the whole design

Mate's call, 2026-08-05: *"the point when claude is 'running' in the computer it can help the user to
setup claude.md ccc command first!!! (so no brew needed at that time) so he can fly... the first is
really ccc, so he can just do it"*.

So `SETUP.md` runs in stages and **the stage boundaries are load-bearing, not decoration**:

- **Stage zero** — download the kit. No account, no login, no keys.
- **Stage one** — `~/projects`, `ccc`, the prove-it check, `cd`/`ls`/`mkdir`, the shell prompt,
  `~/.claude/CLAUDE.md`. **Nothing here may need a password, an install, or a package manager.**
  They type three letters and it works.
- **Stage two** — everything that costs them something: sudo, GitHub, the plugin, the toolbox
  (model, Anthropic plugins, Context7), mise, status bar, Windows terminal colours, and the
  bookmarkable how-to artifact last.

**Moving a step up into stage one is a regression** even when it is technically fine. The reason a
person abandons this is being asked for their password twice before they have seen anything work.
Anything you add goes in stage two unless it genuinely needs nothing.

macOS deliberately does **not** install Homebrew. The agent has its own installer and never needed a
package manager to run — that came out on 2026-08-05 and should not come back.

## The cross-repo coupling — editing a prompt here changes the live website

**`mergodon/matewishkey-web` FETCHES `prompts/install.md` AND `prompts/setup.md` FROM THIS REPO AT
BUILD TIME** (`src/data/genie-prompts.ts`) and renders them on
`matewishkey.com/wishes/put-the-genie-in-the-box`. This repo is the source of truth; the site keeps
no copy. Two consequences:

- **A prompt edit here is a content change to a live public page.** It ships on that site's next
  deploy. There is nothing to sync and nothing to remember, which is the point — but it also means a
  half-finished prompt on `main` is a half-finished prompt on the website.
- **It reads the FIRST fenced block in each file.** Prose around it is for GitHub readers and is not
  published. Add a second fence above the prompt and the site publishes the wrong thing.

**`prompts/setup.md`'s prompt must fit 60 columns.** It is pasted into a terminal, where a longer
line wraps into soup, in the window of the person least able to tell a display artefact from
something they broke. The site's build asserts it and **fails** rather than publishing a wide one, so
a too-long line here breaks somebody else's build. `prompts/install.md` goes into a browser chat and
is deliberately not width-checked.

## The plugin

Three names have to agree or the command in `SETUP.md` is a lie:

- `.claude-plugin/marketplace.json` → `name` (the marketplace) and `plugins[0].name`
- `plugin/.claude-plugin/plugin.json` → `name`, and the two `version` fields must match
- `SETUP.md` step 9 → `claude plugin install <plugin>@<marketplace>`

**`claude plugin validate .` checks the manifests. It does not check that `SETUP.md` quotes them
correctly** — that one is on you, and it broke once already when the repo was renamed.

**Test it by installing it, not by reading it:**

```
claude plugin marketplace add ~/projects/mwk-genie
claude plugin install mwk-genie@matewishkey
claude plugin details mwk-genie@matewishkey     # skills resolve? token cost?
claude plugin uninstall mwk-genie@matewishkey   # this box is a test rig, not a user
claude plugin marketplace remove matewishkey
```

A plugin installed mid-session does not exist in that session — `SETUP.md` tells the user to restart,
and that instruction is why the step works at all.

## It was renamed, and the next rename will be the same job

`matewishkey/putgenieinthebox` → `matewishkey/mwk-genie`, 2026-08-06. GitHub redirects the old path,
which is exactly why it cannot be left to the redirect: it holds only until somebody claims the
freed-up name.

A rename here is **not** just the remote. Sweep, in this order:
`git remote set-url`, the local directory name (`~/projects/<repo>` must equal the repo name), the
clone and tarball URLs in `SETUP.md`, the install path `~/projects/<repo>` in `SETUP.md` and
`prompts/setup.md`, `homepage`/`repository` in both manifests, the plugin name if it carries the repo
name, and `REPO` in **the other repo's** `src/data/genie-prompts.ts`.

`grep -rn "<old-name>" --exclude-dir=.git .` is the check, in both repos.

## Verify identifiers, always

Every URL in this repo is handed to a stranger whose agent will act on it. `curl -o /dev/null -w
'%{http_code}'` each one after any change that touches a path — the raw `SETUP.md` URL, the clone
URL, the tarball URL. A 404 here is not a broken link, it is a beginner's first five minutes.

`templates/ccc.sh` and `templates/prompt.sh` are shell that lands in somebody's `~/.zshrc` or
`~/.bashrc`. Run `bash -n` and `zsh -n` on **both**. A syntax error there breaks every new terminal
they open, on a machine they do not know how to fix. `prompt.sh` branches on `$ZSH_VERSION` and sets
a different variable per shell, so passing the syntax check is not the same as working — source it
in each shell and check `__mwk_git` prints ` (branch)`, ` (branch*)` when dirty, and nothing outside
a repo.

## Cross-repo

- **[mergodon/matewishkey-web](https://github.com/mergodon/matewishkey-web)** — the site, which
  publishes this repo's two prompts. Never edit it from here; file an issue with
  `gh issue create -R mergodon/matewishkey-web`.
