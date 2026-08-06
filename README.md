# Put the genie in the box

**An AI agent, running on your own computer, set up for someone who has never opened a terminal.**

You ask the AI in your browser to sort something out on your computer and it writes you a lovely
answer. Open this file. Change that line. Run this. And you go and do it, and halfway through it says
something red, and now you are carrying error messages back into a chat window like a courier. That
is not the AI doing the job. That is you doing the job, with extra steps.

The other kind lives on your computer. It opens your files, it runs things, and it fixes what it
broke. You agree to the work in conversation — it says what it is about to do, you say yes — and
then it gets on with it instead of asking you to approve every command inside it. **That is a real
trade, and it is why none of this belongs on a work computer.**

This is how you get one. **Two prompts, and you paste them.** You do not need to understand anything
in this repo — the agent reads it, not you.

---

## Step one — into the AI in your browser

This one installs the agent on your machine. It goes in the browser, not a terminal, because if
something on your screen does not match what it says you can take a screenshot and paste it in.

Copy [`prompts/install.md`](prompts/install.md), paste the whole thing into ChatGPT or Claude in your
browser, press enter, and answer its questions.

You want a laptop or a desktop, not a phone. You will need a **Claude Code subscription** — Pro is
the cheapest plan that includes it, and the free plan does not have it.

## Step two — into the agent, once it is running

When the agent is running in a terminal window on your own computer, paste
[`prompts/setup.md`](prompts/setup.md) into it. That one downloads this repo and sets the machine up
from it.

**You do not need a GitHub account to download it** — this repo is public, so it comes down
anonymously with either `git` or `curl`, about 8 KB. You need an account later, in stage two, and by
then you will already have seen the thing work.

[`SETUP.md`](SETUP.md) is the instruction sheet the agent follows once the kit is on your machine.

---

## What you end up with

- **`ccc`** — three letters, from anywhere, and the agent starts in the folder your work lives in,
  ready to work instead of asking you to approve every command. **`ccc holiday-photos`** starts it
  inside that project, so you never have to know where anything is.
- **`~/.claude/CLAUDE.md`** — how it talks to you and how it works, in plain English, in a file you
  can open and change. ([the one it starts with](templates/CLAUDE.md))
- **A `~/projects` folder**, one folder per thing you are doing.
- **Commands for the bits you do over and over** — starting a project, finishing one, getting a
  second opinion on one, and printing out what you learnt today. Say *"start me a new project"* or
  *"save my work"* in normal words, or type `/mwk-genie:` and pick from the list.
  ([what each one does](plugin/skills/))
- **A note left behind every time you finish**, so next time you can open the project and say
  *"carry on"*. Saving writes down where you got to; starting reads it back.
- **GitHub set up**, so every version of your work is kept and "try it and see" stops being
  frightening.
- **`mise`**, so installing a tool never means installing it over the whole machine.
- **A status bar** showing how full the agent's memory is — which matters more than it sounds, and
  `SETUP.md` says why.

**`ccc` and `CLAUDE.md` come first, on purpose.** Neither needs a password, an account or admin
rights, so you are flying inside a couple of minutes. Everything that asks something of you — your
password, a GitHub account — comes after you have seen it work.

## The bits that go wrong

- **The password that shows nothing.** Type your computer password into a terminal and the screen
  does not move. No dots, no stars. It looks broken, so people type it again and lock themselves
  out. It is working. Type it and press enter.
- **"Admin access" means your whole machine**, not one folder. Normal for installing software, and
  exactly the moment to ask the agent what the command does. That question is never annoying.
- **It can delete things.** Same as you can. This is not a toy that is protected from itself, which
  is why the setup puts your work under GitHub before you start playing.
- **It can be wrong and sound completely certain.** Read what it proposes before you say yes.
- **The meter is running.** A long conversation with big files in it costs more than a short one.
  Find your usage page on day one, not after a surprise.
- **Not using Claude?** Any agent that runs in a terminal and can read files works the same way —
  Codex CLI, Gemini CLI, others. Change the name in the prompts. For the status bar, ask it for its
  own equivalent.

## Why "in the box"

A genie in the cloud that can only talk is a chatbot. A genie on *your* machine, that can open *your*
files, is a different animal — more useful, and more able to break something. In the box means both
halves: getting it in there, and knowing where the sides are.

---

From **[Mate Wish Key](https://matewishkey.com)** — a show about what people wish their computer did.
You come on with something you wish yours did, the agent does the work on your machine while we talk
it through, and the wish ends up on the site.

Not affiliated with, sponsored by or endorsed by Anthropic, OpenAI, Google, GitHub or anyone else
named here. They are named because that is what the things are called.
