# Prompt one — paste this into a browser chat

Nothing is on their computer yet, so this runs wherever they already have a chat open. Its job is to get Claude Code installed, signed in, and **started in the mode that makes the rest bearable** — then hand over to prompt two.

**This is the only place anyone is asked anything, and it is one question: Mac or Windows.** The two paths genuinely differ, and no script can ask it before a terminal exists.

```
I have never used a terminal. Walk me through getting Claude Code onto my computer, one step at a time, and wait for me to say a step worked before you start the next one.

Ask me one question first: am I on a Mac or on Windows? Ask me nothing else — decide everything else yourself.

TELL ME WHAT IS ABOUT TO HAPPEN, BEFORE IT HAPPENS

This matters more than anything else here. Every time something is about to be slow, silent, alarming to look at, or costs money, say so in one line FIRST. Not afterwards, and not while I am already worried.

  - If it takes more than a minute, say roughly how long and tell me to go and make a coffee. A progress bar that has not moved for four minutes is where people close the window.
  - If the screen will show nothing while I type, say so before I type. Nothing on screen looks broken.
  - If something opens a window or a browser, say it is about to.
  - If it costs money, say so before I click, and say roughly how much.
  - If a command looks frightening, say what it does in one sentence before I run it.
  - If nothing appears to happen, tell me that is what success looks like here.

WINDOWS
  - I need WSL, which gives me a real Ubuntu terminal inside Windows. Say what that is in one sentence before we do it.
  - There is a way to put the agent straight onto Windows and it looks easier. Do not take it. Everything after this assumes Ubuntu.
  - Check first that this machine can do it: Windows 11, or Windows 10 build 19041 or newer.
  - In PowerShell as Administrator, run `wsl --install`, then restart the computer.
  - Before the restart, tell me it is a real restart and to save anything I have open.
  - After the restart nothing opens by itself. That is not a failure — say so, because waiting for something to appear is where people give up. Tell me to open Ubuntu from the Start menu.
  - The first time it opens it sits there setting itself up for a minute or two before it says anything. Warn me first.
  - Then it asks me to invent a username and password. Before I type: say clearly that this is NOT my Windows password and has nothing to do with my Microsoft account, and that THE SCREEN WILL SHOW NOTHING AT ALL while I type it — no dots, no stars, nothing. That is normal. It is the single place people get most stuck, and they blame themselves for it.
  - From here on, "the terminal" always means the Ubuntu window. If my prompt starts with `PS C:\` I am in the wrong one, and you should say so every time you ask me to open a terminal.

MAC
  - Open Terminal from Spotlight (Command+Space, type "terminal"). That is the only setup I need to reach a terminal.
  - I will need Apple's Command Line Tools before long — real projects want git and a compiler, and the copy of git that ships with macOS is a stub that does nothing until they are installed. Get it over with now rather than in the middle of something.
  - WARN ME FIRST, in about these words: this is a big download from Apple, it usually takes five to fifteen minutes depending on the connection, a window will pop up and I have to click Install, and then there is nothing to do but wait. Tell me to go and make a coffee. It does not ask for a password.
  - Then have me run `xcode-select --install`.
  - The command comes straight back while the download carries on in Apple's own window. That is the trap: it LOOKS finished when it is not. Do not go on until I tell you Apple's window says it is done, and say that to me explicitly rather than assuming I know.
  - Do not install Homebrew. Nothing in this kit uses it.

BOTH, once I have a terminal
  - Tell me plainly, before I sign in to anything, that Claude Code needs a paid Claude plan to be usable, and roughly what it costs. If I do not have one, send me to claude.ai/upgrade and wait for me. Do not skip this to be polite.
  - Warn me that the next one downloads a few hundred megabytes and takes a couple of minutes with very little on screen.
  - Install Claude Code with its own installer: curl -fsSL https://claude.ai/install.sh | bash
  - Check it worked: `claude --version` answers.
  - Warn me that the next line has the word "dangerously" in it and looks alarming on purpose, then explain it BEFORE I run it, not after.
  - Now start it, and use exactly this line: claude --dangerously-skip-permissions
  - Explain that line in about this much: setting up a computer is hundreds of small commands, and the ordinary mode asks me to approve each one. Nobody reads the two-hundredth question — they just press enter, which is worse than not being asked. So for this one session I agree to the work in conversation instead. After setup I will have a shortcut called `ccc` that does the same thing, and one line I can change if I ever want the asking back.
  - Tell me first that it is about to open my web browser to sign me in, so the window appearing is expected rather than something going wrong.

WHEN THAT IS DONE
  Tell me to keep that window open, and that the next thing I paste goes into Claude itself, not into this chat.
```

## What deliberately is not here

No Homebrew, and no package manager of any kind. The kit fetches every tool it needs as a pinned binary, on both platforms, from one list.

Apple's Command Line Tools **are** here, and that is a change of mind: the kit itself does not need them, but the person will, the first time they touch a real project. Better a known five-minute wait now than a mystery dialog in the middle of something they care about.

Nothing here asks for a password except Windows' own WSL setup, which is Microsoft's step and not ours.
