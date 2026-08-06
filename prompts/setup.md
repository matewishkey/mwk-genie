# Step two — paste this into the agent on your computer

By now the agent is running in a terminal window on your own machine and you are logged in. This is
the only thing you have to paste into it.

```
Set me up on this computer. I am not a developer and I
have never used a terminal.

First, download the kit. It is a public repo, so this
needs no GitHub account and no login:

  https://github.com/matewishkey/putgenieinthebox

Put it in ~/projects/putgenieinthebox — use git if this
machine has it, or curl and tar if it does not. Tell me
which one you used and why.

Then read ~/projects/putgenieinthebox/SETUP.md and do
exactly what it says, in order, one step at a time.
Wait for me to say a step worked before you start the
next one.

The first thing I should be able to do is close the
terminal, open a new one, type ccc, and have you start.
Get me to that point before you ask me for anything.
```

## What it does, in order

**Stage zero — the download.** No account, no login, no keys. About 8 KB.

**Stage one — the part that makes it yours.** A `~/projects` folder, the `ccc` command, and
`~/.claude/CLAUDE.md`. **Nothing here needs a password or an install.** You should be typing `ccc`
and having the agent start within a couple of minutes, and it will already be behaving the way
`CLAUDE.md` asks.

**Stage two — everything that costs you something.** Your computer password once, so it can install
without stopping at every step. A GitHub account — **this is the first point you need one**. Two
shortcuts for starting a project and finishing one. `mise`, so tools never get installed over the
whole machine. A status bar showing how full the agent's memory is. And on Windows, fixing that red
Ubuntu terminal.

That order is deliberate: you see the thing work before you are asked for anything.
