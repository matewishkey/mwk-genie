# Step one — paste this into the AI in your browser

Copy everything inside the box. Paste it into ChatGPT or Claude in your browser, press enter, and
answer its questions. It asks which computer you are on first, because Windows and Mac are genuinely
different from here on.

If something on your screen does not match what it described, take a screenshot and drop it into the
chat. It can see pictures. That is why this one goes in the browser rather than a terminal.

```
You are helping me install an AI agent on my own computer.
I am not a developer and I have never used a terminal.
This is step 1 of "Put the genie in the box":
github.com/matewishkey/mwk-genie

This has to be a computer I own. It will run commands on
this machine and later I will let it get on with them
without approving each one. Tell me now, once, if I should
be doing this somewhere other than a work laptop.

Ask me this first, and wait for my answer:

  Are you on Windows, macOS or Linux?

Then take me through it one step at a time. Wait for me to
say a step worked before you start the next one.

WINDOWS
  - We set up WSL, which gives me a real Ubuntu Linux
    terminal inside Windows. Say what that is in one
    sentence before we do it.
  - Open PowerShell as Administrator, run `wsl --install`,
    restart the computer, then pick an Ubuntu username and
    password.
  - The first time I have to paste something into a
    terminal window, tell me how: Ctrl+V, or right-click
    inside the window. Do not skip this. People get stuck
    here and think their copy did not work.
  - Everything after that happens inside Ubuntu, and it
    always will. PowerShell is only for the one command
    above. If you ever give me something to run on
    Windows, you have gone wrong — say which window I
    should be in, every time, until it is obvious.

MACOS
  - The terminal is already there. Open it and go.
  - The agent has its own installer. Do not reach for a
    package manager to install it — Homebrew on a Mac,
    apt on Ubuntu, either one is the wrong tool here.

LINUX
  - Straight to the agent.

WHEN YOU GIVE ME SOMETHING TO COPY
  Put it in a code block on its own, one command per block,
  and nothing else inside the block. Never bury a command
  in the middle of a sentence.

  The first time you do it, tell me there is a copy button
  on the block and that clicking it is safer than selecting
  the text by hand.

  If a command runs past 60 characters, break it across
  lines with a \ at the end of each one. A long line wraps
  in my terminal, I paste it already broken, and then we
  are both chasing an error that was never real.

RULES
  - Use the official install instructions for the agent.
    Do not recite an install command from memory — go and
    check the real documentation first.
  - I do every login myself, in my own browser. Never ask
    me for a password, a code or a token.
  - When I type a password into a terminal, nothing appears
    on the screen. No dots, no stars. Warn me before that
    happens the first time or I will think it is broken.
  - Before each command, tell me what it changes and
    whether it needs admin rights.
  - If I am stuck, remind me I can take a screenshot and
    drop it into this chat.

We are finished when the agent starts on my computer and I
am logged in — nothing else. Do not set anything up for me
beyond that; step 2 does all of it.

Then tell me to paste STEP 2 into the agent on my computer.
Step 2 is on the same page you got this from.

Start by asking me which computer I am on.
```

## Before you start

You need a **Claude Code subscription** — [claude.com/pricing](https://claude.com/pricing). Pro is
the cheapest plan that includes it; the free plan does not have it. That is the bit you pay for.

You do **not** need a GitHub account yet. Step two sets that up for you.
