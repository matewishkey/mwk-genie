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
this machine, and step 2 offers to let it get on with
them without approving each one. Tell me now, once, if I
should be doing this somewhere other than a work laptop.

Step 2 is an opinionated setup: it makes some choices for
me and asks me about three of them. Do not set any of
that up here. Just say it exists so it is not a surprise.

Ask me this first, and wait for my answer:

  Are you on Windows, macOS or Linux?

Then take me through it one step at a time. Wait for me to
say a step worked before you start the next one.

WINDOWS
  - We set up WSL, which gives me a real Ubuntu Linux
    terminal inside Windows. Say what that is in one
    sentence before we do it.
  - This kit is built on WSL. There is a way to install
    the agent straight onto Windows, and it looks easier.
    Do not take it. Everything after step 2 assumes
    Ubuntu, and on Windows it would quietly stop working.
  - Check first that this machine can do it: Windows 11,
    or Windows 10 build 19041 or newer. If the install
    fails with 0x80370102, virtualization is switched off
    in the BIOS and that is the fix, not something I did.
  - Open PowerShell as Administrator, run `wsl --install`,
    then restart the computer.
  - After the restart nothing opens by itself. Tell me to
    open Ubuntu from the Start menu. That is where it asks
    me to make a username and password, and it is the
    step people get stuck on because they are waiting for
    something to happen.
  - Warn me before I type that one: the username must be
    lowercase with no spaces, and nothing at all appears
    on screen while I type the password. No dots, no
    stars. It is not frozen.
  - That Ubuntu password is its own thing. It is not my
    Windows password and it never will be. I will need it
    later, so tell me to remember it now.
  - The first time I have to paste something into a
    terminal window, tell me how: Ctrl+V, or right-click
    inside the window. Do not skip this. People get stuck
    here and think their copy did not work. If it asks
    whether I really want to paste several lines, that is
    normal and the answer is yes.
  - Everything after that happens inside Ubuntu, and it
    always will. PowerShell is only for the one command
    above. If you ever give me something to run on
    Windows, you have gone wrong. Say which window I
    should be in, every time, until it is obvious.

MACOS
  - Ask which version of macOS I am on before anything
    else, and tell me what it means:
      macOS 14 or newer, the normal case, carry on.
      macOS 12 or 13, Homebrew still works but prints a
        scary paragraph about being unsupported. Warn me
        it is expected and not my fault.
      Older than 12, skip Homebrew and iTerm2 entirely.
        Go straight to the agent. I lose nothing that
        matters, because Ctrl+J does the same job.
  - Open Terminal to start. Tell me how: press Cmd+Space,
    type Terminal, press Return. We move to a better one
    in a minute and stay there.
  - Installing Homebrew needs an account that is allowed
    to install software. If somebody else set this Mac up
    for me, I may not have one, and Homebrew stops rather
    than asking. Say so before we start, not after.
  - Install Homebrew, the usual way to install developer
    tools on a Mac. Take the command from brew.sh, not
    from memory.
  - Tell me three things before I start it, not after. It
    asks for my password. If this Mac has never had
    developer tools on it, Homebrew installs Apple's
    Command Line Tools first, which is a big download. And
    that part may open a separate Apple window and then
    sit there waiting for me to press a key when it
    finishes, so a terminal that looks frozen probably is
    not. Then let it run.
  - When it finishes it prints a "Next steps" block. Have
    me run the lines in it before anything else, then have
    me run `brew --version` and tell you what came back.
    On most Macs sold since 2020, brew does not work in
    the window that just installed it until those lines
    are run, and the next command would fail with
    "command not found" for no reason I could guess.
  - Then install a better terminal:
    brew install --cask iterm2
  - Now have me quit Terminal, open iTerm2 the same way
    with Cmd+Space, and do everything from there. It will
    not be in my dock. The first time it opens, macOS asks
    whether I am sure because it came from the internet.
    That is expected and the answer is open.
  - Say why we moved, in one line: in Apple's Terminal,
    Shift+Enter sends the message instead of starting a
    new line, and I will hit that the first time I want to
    write two paragraphs. Also tell me Ctrl+J starts a new
    line in any terminal, in case I ever end up back in
    one that cannot do Shift+Enter.
  - Only then install the agent, using its own
    installer. Not Homebrew. Homebrew was for iTerm2.

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
    Do not recite an install command from memory. Go and
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
am logged in, nothing else. Do not set anything up for me
beyond that; step 2 does all of it.

Then tell me to paste STEP 2 into the agent on my computer.
Step 2 is on the same page you got this from.

Start by asking me which computer I am on.
```

## Before you start

You need a **Claude Code subscription** — [claude.com/pricing](https://claude.com/pricing). Pro is
the cheapest plan that includes it; the free plan does not have it. That is the bit you pay for.

You do **not** need a GitHub account yet. Step two sets that up for you.
