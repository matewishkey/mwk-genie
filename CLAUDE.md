# mwk-genie — agent notes

> ## ⚠️ You are on branch `v2`, and this file still describes v1
>
> **Read [`docs/v2-decisions.md`](docs/v2-decisions.md) first.** It records what changed and what
> was measured. The sections below on **the plugin**, **the two shell templates**, **the learning
> page** and **the two branded pages** describe the v1 design and are being replaced. Everything
> about the **cross-repo coupling**, **verifying identifiers** and **tests that arrange their own
> preconditions** is still true and still load-bearing.
>
> `test/check.sh` fails on this branch — it asserts plugin manifests that no longer exist. That
> rewrite is pending, and a green suite is a precondition for merging.

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
  (model, Anthropic plugins, Context7), mise, status bar, the terminal, and the bookmarkable how-to
  artifact last.

**Moving a step up into stage one is a regression** even when it is technically fine. The reason a
person abandons this is being asked for their password twice before they have seen anything work.
Anything you add goes in stage two unless it genuinely needs nothing.

**Stage one does contain exactly one question** — which `ccc` they want (step 2) — and that is not
a violation of the rule. A question costs them nothing; a password costs them something. Do not
"tidy" it away: shipping `--dangerously-skip-permissions` without asking is the thing that made the
site's copy wrong once already. Three things are the person's to decide, and all three are asked
once and never revisited: `ccc` (step 2), admin access (step 7), the model (step 10).

**The model default is `opus`** — mate's call, 2026-08-11, after testing the kit on sonnet: *"I
tested with sonnet, and it was not working really well."* The recommendation in step 10 and the
framing on the bookmark page both follow from that, so they move together. Sonnet is now presented
as the way to stretch the allowance rather than the starting point.

**Homebrew is for iTerm2 and nothing else. The agent still installs itself.** Amended by mate on
2026-08-11, and the halves are not interchangeable:

- **Never `brew install` Claude Code.** It has its own installer, it has never needed a package
  manager to run, and that was the 2026-08-05 call. `test/rehearse.sh` asserts it: the agent goes in
  with `curl … claude.ai/install.sh | bash` and the run then proves `~/.local/bin/claude` exists.
  (The container is `ubuntu:24.04` and does use `apt-get` — for `curl` and `git` in stage zero, which
  is a different question. The claim is about how the *agent* installs, not about the image.)
- **Homebrew, Xcode Command Line Tools and iTerm2 belong to `prompts/install.md`**, the browser
  prompt, before Claude Code is installed at all.

**The reason it is there rather than in `SETUP.md` is the handoff, and it is the whole point.**
Fixing the terminal *during* `SETUP.md` means the agent tells the person to close the window it is
running in, so it dies mid-setup and a fresh one has to pick the thread up. Installing iTerm2
**before the agent exists** costs nothing to hand over, because there is nothing to hand over.

Step 13 keeps a repair path anyway for anyone who arrives already in Apple's Terminal. Stage one is
untouched by any of this and must stay that way.

### Ctrl+J is the actual fix. iTerm2 is comfort on top of it.

**`Ctrl+J` starts a new line in every terminal, including Apple's, with nothing installed.** It is
in Claude Code's own strings. Learned 2026-08-11, after the iTerm2 path had already been built, and
it changes what that path is *for*: iTerm2 is a nicer terminal that also gets the colours, not the
only way out. **So step 13 offers and takes no for an answer, and Ctrl+J is given first, on every
platform.** Do not let a later edit turn the offer back into an instruction.

**Do not cite the docs table for why Apple's Terminal is different — it is wrong.** Claude Code's
documentation currently lists Apple Terminal among the terminals that work without setup. The real
reason is mechanical: **Apple's Terminal sends the same byte (`0x0d`) for Enter and Shift+Enter, so
there is nothing for any program to bind.** Cite that. Anyone who checks the table instead will
conclude this whole section is unnecessary and delete it.

**`/terminal-setup` does not fix Apple's Terminal**, and `SETUP.md` says so explicitly rather than
staying silent, because the wrong version of that sentence shipped once already (2026-08-10, my
error — inferred from the command's help text instead of checked). It configures VS Code, Cursor,
Devin Desktop, Alacritty and Zed; in Apple Terminal it enables Option-as-Meta and silences the bell
instead. `check.sh` fails if the file mentions it as anything but a warning.

`echo $TERM_PROGRAM` **matches positively on `Apple_Terminal` and acts on nothing else.** Ghostty,
Kitty, WezTerm and Warp all handle Shift+Enter natively, so "anything that is not iTerm2" would talk
those users out of a perfectly good terminal.

**Never write an iTerm2 preference key you have not read off a real Mac.** A wrong `defaults` key
does not error; it writes something nothing reads, and the agent reports success. This fleet has a
logged fabrication of exactly that shape (2026-07-15).

### Read off the observer Mac on 2026-08-11, so nobody re-derives them

The fleet's macOS box is reachable as `matevisky@192.168.172.22` (macOS 26.5.2, arm64, login shell
`/bin/zsh`). These are measured, not remembered:

| Fact | Value | How |
|---|---|---|
| `TERM_PROGRAM` in Apple's Terminal | `Apple_Terminal` | string in `Terminal.app`'s own binary |
| `TERM_PROGRAM` in iTerm2 | `iTerm.app` | string in `iTerm.app`'s own binary |
| iTerm2 preference domain | `com.googlecode.iterm2` (plus `.private`) | `defaults domains` |
| Where profile settings live | a `New Bookmarks` array, **not** top level | PlistBuddy on the live plist |
| Real profile keys | `Guid`, `Name`, `Scrollback Lines`, `Unlimited Scrollback`, `Normal Font` | same |
| Dynamic Profiles folder | `~/Library/Application Support/iTerm2/DynamicProfiles` | exists on that box |

That box is **arm64**, which is worth knowing: the Apple Silicon PATH problem step one guards
against is the default case on any Mac bought in the last few years, not an edge case.

**It says nothing about how people install things, and an earlier version of this note claimed it
did.** That claim — "no Homebrew, iTerm2 installed directly" — was wrong. The box has Homebrew
6.0.15 and iTerm2 came from the cask. The check that produced it ran `bash -lc "command -v brew"`
over SSH; the login shell there is **zsh**, brew's `shellenv` lives in `~/.zprofile`, and bash never
reads it. **So the measurement was the PATH bug, performed by the person documenting the PATH bug.**
Keep that in mind before believing any single-command probe over SSH: a non-interactive remote shell
is not the shell the person uses, and "not found" from it means nothing.

**Everything not in that table is still a guess.** `SETUP.md` step 13 names exactly these and tells
the agent to find anything else the same way.

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

**The closing also clones `mwk-shownotes`, and only ever for somebody who has already said yes to
the invitation above it** (mate's call, 2026-08-13: *"some other might use this library, i do not
want to enforce it"*). That is not a third mention of the show — it is inside one of the two, and it
is conditional on an answer the person has already given.

**It is an offer, not a step**, in the same sense step 13's iTerm2 is: skipped in silence for the
majority who are not guests, and never a fourth thing to walk them through. The "three things are
theirs to decide" rule in `SETUP.md` says so out loud so the count stays honest. Turning it into an
unconditional install would put a conversation-collecting tool on the machine of every stranger who
runs this kit, which is the thing the separate repo exists to avoid.

## The learning page is ONE page, and losing its address is the whole risk

`/mwk-genie:learning` updates a single artifact forever. **A second page is the
failure mode, and it looks exactly like success** — the run publishes, hands over a working link,
and reports done, while the record quietly splits across two addresses.

So the address is kept **twice**: the `<!-- artifact: ... -->` first line of `log.html` (travels
with the record) and `~/.claude/mwk-genie-learning.txt` (survives the folder being deleted or
renamed). Matching the artifact by its exact title is the third way home, which is why the title
must not drift.

**If all three come up empty the skill asks rather than publishing** (mate's call, 2026-08-09).
That is deliberate and it is the one place in that skill where asking beats getting on with it: a
question costs a moment, a duplicate page costs the record. Do not "tidy" it into an automatic
create.

`test/check.sh` pins the title, both stored copies of the address, the ordered recovery steps and
the hand-it-to-publish instruction. **What no script can see is the second run** — it needs a
second day. `test/MANUAL.md` is where it lives, and it is the most valuable line on that list.

## No disclaimer link, and this is settled

The site has `/disclaimer/`, and the kit deliberately does **not** link it (mate's call,
2026-08-09): *"using claude is already a thing... we should not do anything."*

The reasoning is worth keeping because the question will come back the next time somebody reads
`--dangerously-skip-permissions` and gets nervous. Anyone running this has already chosen to
install an AI agent on their own machine; a disclaimer link at the end does not inform that
decision, it just makes the kit read as though it is worried about itself. The honest warnings are
already where they matter — in the two things that will scare you, in step 7's "your whole
machine, not one folder", and in the `ccc` question itself.

Adding it is not a small safe improvement. It changes the tone of the one page they keep.

## The two pages they keep are branded. Nothing else is, and it fetches the brand

`templates/howto.html` and the generated learning page (`log.html`) both carry Mate Wish Key's
look. **Everything else stays deliberately plain** — a setup sheet covered in someone's logo reads
as marketing, and the tone is why people trust this.

**The learning page was added to that list on 2026-08-12** (mate: *"why the what we learnt do not
have a slight design just like a how to... super minimal"*), amending the 2026-08-09 call that made
the bookmark page the only branded file. The reasoning that survives: the split is not
setup-sheet-versus-record, it is **things they keep versus things they read once**. Those two are
the pages that get bookmarked, opened on a phone and printed, so they should read as a pair. The
prompts, `SETUP.md` and the README are read once by an agent or a stranger deciding whether to
start, and stay plain.

**Minimal is the whole instruction.** One block, a rule between entries, no cards, no second red.
If the learning page starts looking like a brochure, that is the drift.

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
up a leading space and get an error they cannot read.

**The learning skill carries its own copy of those three rules** (`plugin/skills/learning/SKILL.md`,
"What it looks like"), because that page is *generated* rather than shipped — nothing in this repo
is the file, so `check.sh` cannot diff it. The skill tells the run to read the design page first and
to lift the block out of `templates/howto.html` rather than draw one. **If you change the three
rules here, change them there too.** `check.sh` asserts that the skill's copy is *present* — it
cannot assert the two still say the same thing, so that pair stays hand-kept.

## The cross-repo coupling — editing a prompt here changes the live website

**`mergodon/matewishkey-web` FETCHES `prompts/install.md` AND `prompts/setup.md` FROM THIS REPO AT
BUILD TIME** (`src/data/genie-prompts.ts`) and renders them on
**`matewishkey.com/wishes/put-the-genie-in-the-box/`** — and **the direction flipped**. This file
used to say `/how-to/…` was canonical and `/wishes/…` was the redirect. Measured 2026-08-30, it is
the other way round: `/how-to/…` **301s to** `/wishes/…`, which is the 200. Their
`public/_redirects` (lines 11-19) folded the how-tos back into the wishes on 2026-08-17, and this
file went on instructing the redirect — the exact thing it warns against. **Write `/wishes/`.**
(Positive control run at the same time: a made-up `/how-to/<anything>` also 301s, so it is a blanket
prefix rule, while a made-up `/wishes/<anything>` 404s — so `/wishes/` is the real routing, not a
second redirect.) This repo is the source of truth for those two files. Two consequences:

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
than a fetch.** `src/content/wishes/put-the-genie-in-the-box.mdx` quotes **the opening of
`templates/CLAUDE.md`** — the first three paragraphs, re-wrapped narrower, inside a
` ```markdown ` fence — and then describes the headings that follow it. Nothing fetches it and
nothing checks it, so **editing the top of `templates/CLAUDE.md` silently makes a live public page
wrong.** The two prompts cannot drift; this can. The quoted fence still matches word for word
(re-verified normalised, 2026-08-30) — but **the fence is the smallest part of the drift.** The
hand-written prose around it also states "two prompts", "three stages", "it asks you three things",
"which of the two brains", "bookmark that one" and "an `mwk` plugin" — every one of which v2
falsifies, and none of which any check can see. There is no `src/content/howtos/` directory; that
path in this file was wrong too. If you change those opening paragraphs or rename an early heading,
say so in the commit and file it across.

## The two shell templates are installed by marker, never appended

`templates/ccc.sh` and `templates/prompt.sh` are each fenced by
`# >>> mwk-genie:<name> >>>` / `# <<< mwk-genie:<name> <<<`, and `SETUP.md` step 2 **replaces
between the markers when they are present**. This is not tidiness.

Appending blindly a second time leaves **two** `alias ccc=` pairs. The instruction on the page they
keep — *move the `#` to the other line* — then edits the first pair while the second one, still the
skip-permissions version, silently wins. **They ask for the safe option and get the dangerous one,
with nothing on screen to tell them.** That is the worst failure this kit is capable of and it was
live until 2026-08-11. `check.sh` now installs twice the documented way, performs the swap, and
asserts what the shell actually ends up with.

**`ccc.sh` also puts `~/.local/bin` on `PATH`, and that line is load-bearing.** The official
installer writes `claude` there and touches no startup file at all — it just prints a note telling
the user to fix PATH themselves. Without our line, `ccc` works in a login shell and is
`command not found` in a non-login one, which is a horrible thing to hand a beginner.

## A test that arranges its own preconditions is worse than no test

Three findings on 2026-08-11 were the same bug in different clothes, and all three had been green
for months:

- `rehearse.sh` wrote `export PATH=$HOME/.local/bin:$PATH` into `.bashrc` **before** appending
  `ccc.sh`, so phase B — which exists to prove `ccc` works in a fresh shell — supplied the one thing
  that would otherwise have made it fail.
- `rehearse.sh` ran `mkdir -p ~/projects` in front of the tarball command it described as *"exactly
  as SETUP.md writes it"*. SETUP.md did not have that line, so the command failed for everyone and
  passed here.
- `check.sh` grepped `SETUP.md` for `"frontend-design"` **with quotes**, which never appears. The
  condition was always false, the `else` always printed a pass, and an invented plugin name passed
  too. Three of the suite's green ticks were counting nothing.

**So: when a check goes green, ask what would have to be true for it to go red.** If you cannot
construct that case, the check is decoration. And if you find yourself adding a step to a test to
make it pass, the bug is in the thing being tested — both scripts now carry a comment saying so at
the exact line where it happened.

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

`grep -rn "<old-name>" --exclude-dir=.git .` is the check, in both repos. **`bash test/check.sh`
now catches the `SETUP.md` half automatically** — it derives the slug from `git remote` and asserts
the clone URL, the tarball URL, the marketplace path and the plugin-install line all match it. It
does **not** check the other repo, the manifests' `homepage`/`repository`, or the links in the
plugin's bug skill — those are still yours to sweep.

## Verify identifiers, always

Every URL in this repo is handed to a stranger whose agent will act on it. A 404 here is not a
broken link, it is a beginner's first five minutes.

**`test/check.sh` extracts the URLs out of the files that ship and curls what it finds** — nothing
to add by hand, and a link you break in `SETUP.md` or on the bookmark page fails the run. It also
fails on a URL that only *redirects* to a working page, because a redirect holds exactly until
somebody claims the freed-up path.

**It used to be a hand-kept list, and this file used to claim it "curls every one of them".** That
was false for as long as it was written: the list checked the URLs somebody remembered to add, which
is not the same set as the URLs a stranger is handed. Breaking a real link in two shipped files left
the suite fully green. If you narrow the extraction, narrow this sentence with it.

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
- **[matewishkey/mwk-shownotes](https://github.com/matewishkey/mwk-shownotes)** — the show-notes
  collector, cloned by this kit's closing for guests only. Deliberately a separate repo and
  deliberately **not** a sixth `/mwk-genie:` command. It carries its own reasoning in its
  `CLAUDE.md`; if the clone URL here ever changes, that is a rename sweep in both places.
