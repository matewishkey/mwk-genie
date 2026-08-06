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

They should not have to remember how to start you. Add a `ccc` function to their shell so typing
three letters opens you in the right place.

`~/projects/mwk-genie/templates/ccc.sh` is the function. Append it to the right file for their
shell — `~/.zshrc` on macOS, `~/.bashrc` on Ubuntu and WSL — and check first whether a `ccc` is
already defined there, so running this twice does not leave two copies.

`ccc` on its own opens you in `~/projects`. **`ccc <folder>` opens you inside that project** — that is
the second half of the shortcut and it is the one they will use every day. Say it once now; step 6
gives them a command that ends by handing them the name to type.

**Then tell them to open a new terminal window and type `ccc`.** A shell only reads that file when it
starts, so the command does not exist in the window they are sitting in. If you skip this they will
type `ccc`, see `command not found`, and reasonably conclude it failed.

That is the moment this whole thing works. Let them do it.

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

### 6. The two shortcuts

They can start you now, but nothing yet helps them **start a project** or **finish one**. That is
what this step adds, and it comes straight after GitHub because both commands lean on it.

The kit they downloaded in stage zero is also a plugin catalogue, so this installs off their own
disk rather than the internet:

```
claude plugin marketplace add ~/projects/mwk-genie
claude plugin install mwk-genie@matewishkey
```

That gives them two commands, in every folder, from now on:

- **`/mwk-genie:new-project`** — makes a folder in `~/projects`, turns on save points, puts a private
  copy on GitHub, and ends by telling them the `ccc <name>` that reopens it.
- **`/mwk-genie:save`** — says in plain English what changed, writes a note to next time in the
  project's `TODO.md`, makes a save point, pushes it, and tells them how to start a fresh
  conversation without losing any of it.

That note is the reason `save` is worth having over a plain save point. The `CLAUDE.md` you copied
in step 3 tells you to read it when you open a project, so "carry on" is a complete instruction the
next morning.

**Tell them they never have to type either one.** "Start me a new project" and "save my work" reach
the same place. The slash commands are there for when they would rather point than talk, and
`/mwk-genie:` in the box will list them.

**Then have them restart you** — close the window and type `ccc`. A plugin installed mid-session
does not exist in that session, and the symptom is the command simply not being there. They have
`ccc` by now, so this restart costs them three letters.

### 7. mise

Install `mise`, and use it for every language and tool you install from now on instead of installing
things system-wide. It keeps their machine clean and lets different projects want different versions
without a fight.

### 8. Your status bar

Set up your status bar so they can always see **how full your context window is**, which model they
are talking to, and which folder they are in. Use your own supported way of doing it.

Tell them why the first one matters: you can only hold so much of a conversation at once, and when
that fills up the older parts get squeezed out. Without the bar, that just feels like you going
stupid on them for no reason.

### 9. Terminal colours — Windows only

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
- **One thing at a time.** Wait for them to say a step worked before starting the next one.
- **If they are stuck, remind them they can take a screenshot and paste it in.** You can see
  pictures.

## When you are done

Tell them the setup is finished, and give them the three things worth remembering — no more than
three:

- **`ccc`** brings you back, and **`ccc <folder>`** brings you back to a project.
- **"start me a new project"** and **"save my work"** are the two things that need doing often.
- **`~/.claude/CLAUDE.md`** is where they change how you behave.

Then ask them what they actually wanted their computer to do — that is the thing they came for, and
everything above was only the box.
