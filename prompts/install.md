# Prompt one — paste this into a browser chat

They have no agent on their computer yet, so this one runs in a browser —
claude.ai, or any chat they already have open. Its whole job is to get Claude Code
installed and signed in, and then hand over to prompt two.

**This is the only place anyone is asked anything, and it is one question: Mac or
Windows.** The two paths genuinely differ — Windows needs WSL first — and no
script can answer it before it exists.

```
I have never used a terminal. Walk me through
getting Claude Code onto my computer, one step at
a time, and wait for me to say a step worked
before you start the next one.

Ask me one question first: am I on a Mac or on
Windows? Ask nothing else — decide the rest.

WINDOWS
  - I need WSL, which gives me a real Ubuntu
    terminal inside Windows. Say what that is in
    one sentence before we do it.
  - There is a way to put the agent straight onto
    Windows and it looks easier. Do not take it.
    Everything after this assumes Ubuntu.
  - Check first: Windows 11, or Windows 10 build
    19041 or newer.
  - In PowerShell as Administrator: wsl --install
    then restart the computer.
  - After the restart nothing opens by itself.
    Tell me to open Ubuntu from the Start menu.
    That is where it asks me to invent a username
    and password. Say clearly that this password
    is NOT my Windows password, and that it will
    not show anything on screen as I type it.
  - From here on, "the terminal" always means the
    Ubuntu window. If my prompt starts with
    PS C:\ I am in the wrong one.

MAC
  - Open Terminal from Spotlight. That is all the
    setup I need.
  - Do not install Homebrew and do not install
    Xcode tools. Nothing here needs either.

BOTH, once I have a terminal
  - Install Claude Code with its own installer:
    curl -fsSL https://claude.ai/install.sh | bash
  - Then have me run: claude
    It will open a browser to sign me in.
  - I need a paid Claude plan for this to be
    usable. If I do not have one, send me to
    claude.ai/upgrade and wait. Tell me plainly
    that this costs money before I click.
  - Check it worked: claude --version answers.

WHEN THAT IS DONE
  Tell me to keep the terminal open, and that the
  next thing I paste goes into Claude itself, not
  into this chat.
```

## What deliberately is not here

No Homebrew, no Xcode Command Line Tools, no package manager of any kind. The kit
fetches every tool it needs as a pinned binary. Homebrew's last remaining case was
iTerm2, and the kit installs that itself, from the vendor's own zip, into
`~/Applications` — which needs no password.

Nothing here asks for a password except Windows' own WSL setup, which is Microsoft's
step and not ours.
