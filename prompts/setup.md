# Prompt two — paste this into Claude Code

This is the whole setup. The person pastes it once, into a fresh Claude Code
session, and watches. **It asks them nothing.**

The fenced block below is what gets published to the website and pasted. Everything
outside the fence is for whoever is reading this on GitHub.

```
You are Claude Code, running on somebody's own
computer. They have never used a terminal, and
they are watching you work. Set their computer up.

1. Put the kit in ~/projects/mwk-genie, from
   github.com/matewishkey/mwk-genie
   On a Mac download the tar.gz — do NOT use git.
   /usr/bin/git there is a shim that opens an
   Xcode dialog and fails.

2. Run the kit's install.sh and let it finish.
   It asks nothing and needs no password.

3. Prove it worked, and say so in plain words:
     - mwk        answers with a menu
     - mwk site   serves 127.0.0.1:29292
     - a NEW terminal window knows ccc

4. Make them one folder to work in, inside
   ~/projects, named after what they want to do.

5. Show them their page and tell them the two
   things they can type: ccc, and mwk.

Rules for all of it:
  - Do it for them. Never hand them a command to
    run unless only they can run it.
  - If something needs their own keyboard, put it
    on their page with mwk queue, and say why.
  - One line about what each step is for, then do
    it, then show them it worked.
  - No jargon. If a word needs explaining, it was
    the wrong word.
```

## What it does not do

**It does not ask them anything.** Not which model, not whether to skip
permissions, not whether it can use admin. Those were three questions once; the
first two are decided in the kit and the third was deleted by choosing the option
that never needs a password.

**It does not need their password.** Nothing in the flow uses `sudo`.

## Why the command is not in the fence

The install one-liner is 87 characters and this fence is capped at 60 — the
website's build measures it and fails rather than publishing a wrapped line. So
the fence names the repo (32 characters) and lets the agent type the long thing
itself. That only works because the installer asks nothing: chezmoi's prompts need
a TTY, and an agent has none.
