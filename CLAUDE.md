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

**Stage one does contain exactly one question** — which `ccc` they want (step 2) — and that is not
a violation of the rule. A question costs them nothing; a password costs them something. Do not
"tidy" it away: shipping `--dangerously-skip-permissions` without asking is the thing that made the
site's copy wrong once already. Three things are the person's to decide, and all three are asked
once and never revisited: `ccc` (step 2), admin access (step 7), the model (step 10).

macOS deliberately does **not** install Homebrew. The agent has its own installer and never needed a
package manager to run — that came out on 2026-08-05 and should not come back.

## The show is the point, and it is mentioned in exactly two places

This kit is **pre-show homework** — the site says so outright on the genie page ("You do this once,
before the show"). The concept is come on the show and build the thing together; the box is only the
box. So the kit ends by pointing at it, in two places and no others (mate's call, 2026-08-08):

- **`templates/howto.html`** — the closing section. That page is the one artefact they keep and open
  on their phone, which makes it the only high-value spot.
- **`SETUP.md`'s closing** — right after asking what they actually wanted their computer to do,
  because that answer *is* a show.

Links, all checked by `test/check.sh`: `matewishkey.com/show/`, `youtube.com/@matewishkey`,
`twitch.tv/matewishkey`.

**Deliberately not in the README front matter and not in the generated learning page.** Two
invitations is an invitation; five is a funnel, and the tone of everything else here is the reason
people trust it. If you are adding a third, you are probably wrong.

(The README's *footer* does mention the show, in prose, with no `/show` link. That predates the rule
and sits inside it — it is a colophon, not a call to action. Leave it alone.)

## The bookmark page is the only branded thing, and it fetches the brand

`templates/howto.html` is the page they keep. It is **the one file in this kit that carries Mate
Wish Key's branding** (mate's call, 2026-08-09) — everything else is deliberately plain, because a
setup sheet covered in someone's logo reads as marketing and the tone is why people trust this.

It does not hardcode the brand and hope. **`SETUP.md`'s last step tells the publishing agent to
read <https://matewishkey.com/design/> first and correct any token that has moved** — that page
renders the site's real values live, so the page cannot drift away from the site. That instruction
is the anti-drift mechanism; deleting it turns the file into another hand-copied brand asset going
quietly stale, which is exactly the failure logged against `matewishkey-web#29`.

Three rules out of that design kit, all enforced by `test/check.sh`:

- **Red is spent once** — the block, top-left. "The block reads as loud because of how much page is
  around it, so spending the red twice spends the effect." The copy buttons are deliberately
  neutral, and the check fails if one turns red.
- **Red is never body text.** At body size the only red allowed is `--red-deep`, for links.
- **The block is the real logo file**, inlined verbatim from `matewishkey.com/favicon.svg`. Do not
  hand-build a red square with a mark in it — `check.sh` diffs the path data against the live file.

**It was markdown until 2026-08-09** and became HTML for one reason: copy buttons. Every command on
it is something a beginner has to type, and selecting text by hand in a browser is where they pick
up a leading space and get an error they cannot read. The learning page (`log.html`) got the same
buttons and **none** of the branding.

## The cross-repo coupling — editing a prompt here changes the live website

**`mergodon/matewishkey-web` FETCHES `prompts/install.md` AND `prompts/setup.md` FROM THIS REPO AT
BUILD TIME** (`src/data/genie-prompts.ts`) and renders them on
`matewishkey.com/how-to/put-the-genie-in-the-box/` (the old `/wishes/…` path still 301s, but a
redirect is not a home). This repo is the source of truth for those two
files. Two consequences:

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

**There is a THIRD coupling and it is the dangerous one, because it is a hand-typed copy rather
than a fetch.** `src/content/howtos/put-the-genie-in-the-box.mdx` quotes **the opening of
`templates/CLAUDE.md`** — the first three paragraphs, re-wrapped narrower, inside a
` ```markdown ` fence — and then describes the headings that follow it. Nothing fetches it and
nothing checks it, so **editing the top of `templates/CLAUDE.md` silently makes a live public page
wrong.** The two prompts cannot drift; this can. Checked accurate 2026-08-09; filed as an issue on
that repo. If you change those opening paragraphs or rename an early heading, say so in the commit
and file it across.

## The plugin

Three names have to agree or the command in `SETUP.md` is a lie:

- `.claude-plugin/marketplace.json` → `name` (the marketplace) and `plugins[0].name`
- `plugin/.claude-plugin/plugin.json` → `name`, and the two `version` fields must match
- `SETUP.md` step 9 → `claude plugin install <plugin>@<marketplace>`

**`claude plugin validate .` checks the manifests. It does not check that `SETUP.md` quotes them
correctly** — that one broke once already when the repo was renamed. **`test/check.sh` now does
check it**, along with the version match and whether every skill is actually documented.

**Test it by installing it, not by reading it** — `test/rehearse.sh` phase C does exactly that in a
clean container, with real Claude Code, and leaves this box alone. Reach for the manual recipe only
when you are debugging the rehearsal itself:

```
HOME=$(mktemp -d) claude plugin marketplace add ~/projects/mwk-genie   # isolate; do not
HOME=$(mktemp -d) claude plugin install mwk-genie@matewishkey          # pollute real config
```

Verified facts worth not re-deriving: **plugin install needs no login**, `marketplace add <path>`
reads the working tree rather than fetching the remote, and installing writes
`extraKnownMarketplaces` + `enabledPlugins` into `~/.claude/settings.json` — which is what step 10's
"merge, do not overwrite" warning is protecting.

A plugin installed mid-session does not exist in that session — `SETUP.md` tells the user to restart,
and that instruction is why the step works at all.

## Test it before you push

```
bash test/check.sh      # seconds, no Docker
bash test/rehearse.sh   # minutes, Docker, a clean ubuntu:24.04 with no git and no curl
```

`test/README.md` says what each covers; `test/MANUAL.md` is the short list of what needs a browser,
a login, or a human. **Do not run git commands against the container's copy of the kit** — your
changes are uncommitted, so a stray `stash` reverts it to published `main` and the run silently
tests the wrong thing. That happened while writing the scripts; phase A now asserts the version to
catch it.

## It was renamed, and the next rename will be the same job

`matewishkey/putgenieinthebox` → `matewishkey/mwk-genie`, 2026-08-06. GitHub redirects the old path,
which is exactly why it cannot be left to the redirect: it holds only until somebody claims the
freed-up name.

A rename here is **not** just the remote. Sweep, in this order:
`git remote set-url`, the local directory name (`~/projects/<repo>` must equal the repo name), the
clone and tarball URLs in `SETUP.md`, the install path `~/projects/<repo>` in `SETUP.md` and
`prompts/setup.md`, `homepage`/`repository` in both manifests, the plugin name if it carries the repo
name, the URLs in `test/check.sh` and `test/rehearse.sh`, the `gh issue create -R` target and the
`issues/new/choose` link in `plugin/skills/bug/SKILL.md`, the same link in `README.md`, **the repo
URL inside the published fence of `prompts/install.md`** — that one ships straight to the live site —
and `REPO` in **the other repo's** `src/data/genie-prompts.ts`.

`grep -rn "<old-name>" --exclude-dir=.git .` is the check, in both repos — and `bash test/check.sh`
catches the `SETUP.md` half automatically.

## Verify identifiers, always

Every URL in this repo is handed to a stranger whose agent will act on it. A 404 here is not a
broken link, it is a beginner's first five minutes. **`test/check.sh` curls every one of them** —
run that rather than spot-checking by hand, and add any new URL to it in the same commit.

`templates/ccc.sh` and `templates/prompt.sh` are shell that lands in somebody's `~/.zshrc` or
`~/.bashrc`. A syntax error there breaks every new terminal they open, on a machine they do not know
how to fix — and passing a syntax check is not the same as working: `prompt.sh` branches on
`$ZSH_VERSION` and sets a different variable per shell, and `ccc.sh` ships two alias lines of which
exactly one must be live. `check.sh` sources both files in both shells and asserts the behaviour;
`rehearse.sh` goes further and runs `ccc` in a genuinely fresh interactive shell against a stub
`claude`, which is the show-001 failure reproduced on purpose.

## Cross-repo

- **[mergodon/matewishkey-web](https://github.com/mergodon/matewishkey-web)** — the site, which
  publishes this repo's two prompts. Never edit it from here; file an issue with
  `gh issue create -R mergodon/matewishkey-web`.
