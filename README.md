# Mate Wish Key — put the genie in the box

An AI agent, running on your own computer, set up for someone who has never opened a terminal.

**Two things to paste, one question to answer, and no password.**

> This is homework for [the show](https://matewishkey.com/show/). You do it once, on your own machine, and then we build the thing you actually wanted — together, on air.

## How it goes

1. **[Paste prompt one](prompts/install.md)** into any chat you already have open. It asks whether you are on a Mac or on Windows — the only question in the whole process — and gets Claude Code onto your computer and signed in.
2. **[Paste prompt two](prompts/setup.md)** into Claude Code itself. It reads the installer, tells you what it does, runs it, checks its own work, and makes you somewhere to start.

That is the whole thing. It does not ask which model, whether it may use admin, or whether to check with you before each step. Those were questions once; they are decided now, and the one that is worth changing your mind about is one character in a file the setup shows you.

## What you end up with

| | |
|---|---|
| `ccc` | starts the agent, from anywhere |
| `mwk` | a menu: start something, see your keys, open your page |
| `http://127.0.0.1:29200/` | your page — what you can type, and anything the agent needs you to run |
| `~/projects/<your thing>/` | your work, with an `input` folder to drop things into |
| `~/.mwk/` | your keys, behind one password that only you know |

Plus five things you can ask for by name: `/mwk-new` starts a project, `/mwk-save` saves and pushes it, `/mwk-learning` adds to your running record of what you have learnt, `/mwk-magic` is a second opinion, `/mwk-bug` reports anything in here that is broken.

## The two things that will scare you

**It runs commands without asking.** That is deliberate — setting up a computer is hundreds of small commands, and approving them one at a time means you stop reading and start pressing enter, which is worse than not being asked. **This is why it does not belong on a work computer.** To turn the asking back on, move one `#` in `~/.mwk-shell.sh`; the setup shows you the line.

**It can see and change things in your home folder.** Not just one project. That is what makes it useful and it is worth knowing.

## Taking it off again

```
mwk uninstall
```

It removes everything it put there and asks before touching anything that is yours. **Your keys and your work go to the trash, not the bin** — a password store that vanishes on a typo would be the worst thing this kit could do. It tells you where they went.

`sh ~/projects/mwk-genie/uninstall.sh --dry-run` says what would go without touching anything.

## Keys

Never put an API key in a file or in the chat. `mwk add NAME` stores one behind a single master password; `mwk run -- <command>` hands the values to that one command and they vanish with it. **Save that master password in your password manager the moment you make it** — nobody can reset it. If it ever gets out, `mwk rekey` is one command.

The agent cannot type it and will not ask you to give it one. Anything that genuinely needs your keyboard appears on your page with a Copy button and a line saying why.

## No package manager

No Homebrew, no apt. Every tool is a pinned binary from its own project, fetched by `mise` from one list ([`mise.toml`](mise.toml)), identical on macOS, Ubuntu and WSL. On a Mac it also installs Apple's Command Line Tools, because you will want git before long.

## Working on the kit itself

[`CLAUDE.md`](CLAUDE.md) is the notes for whoever changes this repo — the reasoning, and the things that will bite you. [`test/`](test/) says what is checked automatically and what still needs a human.

Something broken? `/mwk-bug` writes the report for you, or [open one here](https://github.com/matewishkey/mwk-genie/issues/new/choose).
