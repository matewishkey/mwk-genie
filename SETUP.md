# Set yourself up

**You are Claude Code, running on somebody's own computer. They are not a developer and they have
never used a terminal.** They have just installed you and logged in, and this is the first thing
they have asked you to do.

Work through the three stages below **in order**. Say one line about what each step is for, do it,
then show them it worked before moving on.

---

## Stage zero — get the kit onto their machine

**No GitHub account, no login and no keys.** This repo is public, so it downloads anonymously. Put it
in their projects folder — it becomes the worked example of what a project folder looks like, and it
is what you point at later when something needs explaining.

    ~/projects/mwk-genie

Use whichever of these the machine can actually do — **check before you run one**, because a minimal
Ubuntu or WSL image ships with neither `git` nor `curl` guaranteed:

```
git clone https://github.com/matewishkey/mwk-genie.git \
  ~/projects/mwk-genie
```

```
curl -L https://github.com/matewishkey/mwk-genie/archive/refs/heads/main.tar.gz \
  | tar xz -C ~/projects && mv ~/projects/mwk-genie-main \
  ~/projects/mwk-genie
```

If neither tool is there, install one — that is the one thing in stage zero that may need their
password, and it is worth saying so out loud rather than surprising them with a prompt.

**Everything from here reads the files you just downloaded**, not the internet. If you are working
from a web copy of this document instead, get the repo down first; the templates are the point.

---

## Stage one — get them flying

**Nothing in this stage needs a password, an install, or an internet connection.** It is two files
and a folder, all of it local now. Do all of it before you ask them for anything, because a person
who has been asked for their password twice before they have seen the thing work is a person who is
already nervous.

### 1. A folder for their work

    ~/projects

Already there from stage zero. One folder per project inside it, side by side. Tell them the full
path, and work there from now on.

### 2. The `ccc` command

They should not have to remember how to start you. Add `ccc` to their shell so three letters do it.

`~/projects/mwk-genie/templates/ccc.sh` is one line. Append it to the right file for their shell —
`~/.zshrc` on macOS, `~/.bashrc` on Ubuntu and WSL — and check first whether a `ccc` is already
defined there, so running this twice does not leave two copies.

**It starts you where they are standing. It does not move them.** That is deliberate: which folder
they are in is real and they are better off knowing it than having it hidden.

**Then tell them to open a new terminal window and type `ccc`.** A shell only reads that file when it
starts, so the command does not exist in the window they are sitting in. If you skip this they will
type `ccc`, see `command not found`, and reasonably conclude it failed.

That is the moment this whole thing works. Let them do it.

**Say this once, before they run it, and then never again:**

> From here I will not stop and ask you before each thing I do. You still agree to the work — I
> say what I am about to do and you say yes — but I will not make you approve it a second time,
> command by command. That is the trade for not sitting here pressing enter for an hour. **Do not
> set this up on a work computer.**

One warning, one sentence each. Not a section, not a lecture.

### 2b. Prove it actually worked

**Do not move on until you have checked this.** The command can exist and still not do the thing,
and a beginner cannot tell the difference — they see you start and assume it is fine.

Once they are in the new window, check how you were launched:

```
ps -o args= -p $PPID
```

You want `--dangerously-skip-permissions` in that line. If it is not there, the shortcut did not
take — fix it and check again before step 3.

Then tell them what you found, in one line, either way. This is the step that failed silently the
first time it met a real person.

### 2c. Three commands they should actually know

Not a lesson. Show them these three, once, in the terminal in front of them, and let them try each:

    cd projects      move into a folder
    ls               what is in this one
    mkdir <name>     make a new one

**They are not developers, but they are not helpless either.** Knowing where they are is the
difference between driving and being driven, and it takes about a minute. Everything else they can
ask you for.

### 3. `CLAUDE.md` — how you work with them

`~/projects/mwk-genie/templates/CLAUDE.md` is the file. Copy it to **`~/.claude/CLAUDE.md`**,
which is the one you read at the start of every session in every folder — so the rules hold
tomorrow, and in projects that do not exist yet.

Tell them where it is and that it is theirs: plain English, open it and change it whenever something
you do annoys them. Show them one line from it so they know what editing it would look like.

**Read it now and follow it for the rest of this setup**, including the parts that make the next
stage slower. It is not paperwork; it is the instructions.

---

## Stage two — the rest

Now the things that need a password or a download. Say what each one is for in one line first.

### 4. Sudo

Ask for their computer password **once**, so you can install things without stopping at every step.

**Warn them before they type it that nothing will appear on screen** — no dots, no stars. It is the
single most common place people think their computer has frozen, and they type it three times and
lock themselves out.

### 5. GitHub

**This is the first step that needs an account**, and it is worth saying so — they have had a working
setup for several minutes at this point without one, which is the honest picture.

Sign them in from this computer using GitHub's official command-line tool. **They do the login in
their own browser** — never ask them for a password, a code or a token. Set their name and email so
save points have an author.

Then say, in one sentence, what it buys them: every version of their work is kept, so "try it and
see" stops being frightening. If you downloaded this kit with `git` in stage zero, the folder in
front of them is already a repo — use it as the example rather than describing one.

### 6. The commands

They can start you now, but nothing yet helps them **start a project** or **finish one**. That is
what this step adds, and it comes straight after GitHub because those two lean on it.

The kit they downloaded in stage zero is also a plugin catalogue, so this installs off their own
disk rather than the internet:

```
claude plugin marketplace add ~/projects/mwk-genie
claude plugin install mwk-genie@matewishkey
```

That gives them four commands, in every folder, from now on:

- **`/mwk-genie:new-project`** — makes a folder in `~/projects`, turns on save points, puts a private
  copy on GitHub, and ends by telling them the two lines that reopen it.
- **`/mwk-genie:save`** — says in plain English what changed, writes a note to next time in the
  project's `TODO.md`, makes a save point, pushes it, and tells them how to start a fresh
  conversation without losing any of it.

- **`/mwk-genie:magic`** — steps back and looks at a project with fresh eyes: what is this actually
  for, and where has it drifted away from that. Summoned when they want a second opinion.
- **`/mwk-genie:learning`** — a cheat sheet of what they learnt today, across every project, built
  from their own conversations and written as a page they can print.

That note is the reason `save` is worth having over a plain save point. The `CLAUDE.md` you copied
in step 3 tells you to read it when you open a project, so "carry on" is a complete instruction the
next morning.

**Tell them they never have to type either one.** "Start me a new project" and "save my work" reach
the same place. The slash commands are there for when they would rather point than talk, and
`/mwk-genie:` in the box will list them.

**Then have them restart you** — close the window and type `ccc`. A plugin installed mid-session
does not exist in that session, and the symptom is the command simply not being there. They have
`ccc` by now, so this restart costs them three letters.

### 7. Make yourself good at the work

Three small things, all one-off, none of which they will ever have to think about again.

**The model.** They are going to be building things, so put the strongest one in front of them by
default. In `~/.claude/settings.json`:

```
"model": "opus"
```

**Merge that key in — do not overwrite the file.** Step 6 already wrote to it, and clobbering it
uninstalls the commands you just gave them. It is read at start-up, so it takes effect next time
they run `ccc`, not this second.

**Plugins.** Anthropic publishes a set, and three of them earn their place for someone building
things rather than maintaining them:

```
claude plugin marketplace add \
  https://github.com/anthropics/claude-code.git
claude plugin install frontend-design@claude-code-plugins
claude plugin install feature-dev@claude-code-plugins
claude plugin install security-guidance@claude-code-plugins
```

- **frontend-design** — so anything with a screen comes out looking like somebody made a decision,
  not like a template.
- **feature-dev** — understands the shape of what is already there before adding to it.
- **security-guidance** — warns when an edit is about to do something risky. They cannot yet spot
  that themselves, and this is the one that is watching while they learn.

Use the `https://` form above rather than the `anthropics/claude-code` shorthand — the shorthand
clones over SSH, and they have no SSH key.

**Live documentation.** Add Context7, which looks up the real, current documentation for whatever
tool they are using:

```
claude mcp add --transport http context7 \
  https://mcp.context7.com/mcp
```

No account and no key. Say why in one line, because it is the most useful sentence in this step:
**this is what stops you confidently telling them a command that does not exist.** That failure is
not hypothetical — it is what put a wrong install command on air on the first show.

Then have them restart you once more so all of it loads.

### 8. mise

Install `mise`, and use it for every language and tool you install from now on instead of installing
things system-wide. It keeps their machine clean and lets different projects want different versions
without a fight.

### 9. Your status bar

Set up your status bar so they can always see **how full your context window is**, which model they
are talking to, and which folder they are in. Use your own supported way of doing it.

Tell them why the first one matters: you can only hold so much of a conversation at once, and when
that fills up the older parts get squeezed out. Without the bar, that just feels like you going
stupid on them for no reason.

### 10. Terminal colours — Windows only

Their Ubuntu terminal has a red background by default and it is horrible. Change the colour scheme to
Tokyo Night dark: background `#1a1b26`, text `#c0caf5`. Take the rest of the palette from the
official tokyonight project rather than from memory.

---

## Rules for this whole setup

- **Use the official install instructions** for anything you install. Do not recite an install
  command from memory — go and check the real documentation first.
- **They do every login themselves, in their own browser.** Never ask them for a password, a code or
  a token. Their computer password in step 4 is the one exception, and it is typed into their own
  terminal, not to you.
- **Before each command, say what it changes** and whether it needs admin rights.
- **Anything they have to paste goes on its own line, and breaks at 60 characters with a `\`.** This
  holds from the first command, not from step 3 when you copy their `CLAUDE.md` — a wrapped line
  pastes broken and they cannot tell that from a real error.
- **One thing at a time.** Wait for them to say a step worked before starting the next one.
- **If they are stuck, remind them they can take a screenshot and paste it in.** You can see
  pictures.

## When you are done

Tell them the setup is finished, and give them the three things worth remembering — no more than
three:

- **`cd projects/<name>`** then **`ccc`** brings you back to a project.
- **"start me a new project"** and **"save my work"** are the two things that need doing often.
- **`~/.claude/CLAUDE.md`** is where they change how you behave.

Then ask them what they actually wanted their computer to do — that is the thing they came for, and
everything above was only the box.
