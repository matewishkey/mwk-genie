# Prompt one — paste this into a browser chat

Nothing is on their computer yet, so this runs wherever they already have a chat open. Its job is to get Claude Code installed, signed in, and **started in the mode that makes the rest bearable** — then hand over to prompt two.

**This is the only place anyone is asked anything, and it is one question: Mac or Windows.** The two paths genuinely differ, and no script can ask it before a terminal exists.

```
I have never used a terminal. Walk me through getting Claude Code onto my computer, one step at a time, and wait for me to say a step worked before you start the next one.

Ask me one question first: am I on a Mac or on Windows? Ask me nothing else — decide everything else yourself.

WINDOWS
  - I need WSL, which gives me a real Ubuntu terminal inside Windows. Say what that is in one sentence before we do it.
  - There is a way to put the agent straight onto Windows and it looks easier. Do not take it. Everything after this assumes Ubuntu.
  - Check first that this machine can do it: Windows 11, or Windows 10 build 19041 or newer.
  - In PowerShell as Administrator, run `wsl --install`, then restart the computer.
  - After the restart nothing opens by itself. Tell me to open Ubuntu from the Start menu. That is where it asks me to invent a username and password. Say clearly that this password is NOT my Windows password, and that the screen will show nothing at all while I type it — that is normal, and it is where people get stuck and blame themselves.
  - From here on, "the terminal" always means the Ubuntu window. If my prompt starts with `PS C:\` I am in the wrong one, and you should say so every time you ask me to open a terminal.

MAC
  - Open Terminal from Spotlight (Command+Space, type "terminal"). That is the only setup I need to reach a terminal.
  - I will need Apple's Command Line Tools before long — real projects want git and a compiler, and the copy of git that ships with macOS is a stub that does nothing until they are installed. Get it over with now rather than in the middle of something: have me run `xcode-select --install`, then click Install in the window Apple pops up, and wait for it to finish. It is a big download and it asks for no password.
  - Do not install Homebrew. Nothing in this kit uses it.

BOTH, once I have a terminal
  - Tell me plainly, before I sign in to anything, that Claude Code needs a paid Claude plan to be usable, and roughly what it costs. If I do not have one, send me to claude.ai/upgrade and wait for me. Do not skip this to be polite.
  - Install Claude Code with its own installer: curl -fsSL https://claude.ai/install.sh | bash
  - Check it worked: `claude --version` answers.
  - Now start it, and use exactly this line: claude --dangerously-skip-permissions
  - Explain that line in about this much: setting up a computer is hundreds of small commands, and the ordinary mode asks me to approve each one. Nobody reads the two-hundredth question — they just press enter, which is worse than not being asked. So for this one session I agree to the work in conversation instead. After setup I will have a shortcut called `ccc` that does the same thing, and one line I can change if I ever want the asking back.
  - It will open a browser to sign me in the first time.

WHEN THAT IS DONE
  Tell me to keep that window open, and that the next thing I paste goes into Claude itself, not into this chat.
```

## What deliberately is not here

No Homebrew, and no package manager of any kind. The kit fetches every tool it needs as a pinned binary, on both platforms, from one list.

Apple's Command Line Tools **are** here, and that is a change of mind: the kit itself does not need them, but the person will, the first time they touch a real project. Better a known five-minute wait now than a mystery dialog in the middle of something they care about.

Nothing here asks for a password except Windows' own WSL setup, which is Microsoft's step and not ours.
