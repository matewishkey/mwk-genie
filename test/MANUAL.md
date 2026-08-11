# The bits no script can check

`check.sh` and `rehearse.sh` cover everything mechanical. What is left needs a browser, a
login, or somebody actually reading the thing. Walk this when the prompts, the setup sheet,
or the two published pages change.

## Needs a login

- [ ] **Step 1 works in a browser.** Paste `prompts/install.md` into a fresh ChatGPT or Claude
      conversation. It should ask which computer you are on **first**, and stop once the agent
      is running and logged in — not carry on into setup.
- [ ] **The artifact publishes.** Run `/mwk-genie:learning` in a signed-in session. Check a page
      appears, the link opens, and it prints.
- [ ] **It publishes to the *same* page the second time.** Run it again on another day, or after
      a `/clear`. **Today's entry goes on top, yesterday's is still underneath, and the URL has
      not changed.** This is the whole point of the command and the only part that cannot be
      automated — a second copy at a new address is the failure, and it looks like success.
- [ ] **Both copies of the address get written.** After a run, check the first line of
      `~/projects/what-we-learnt/log.html` is `<!-- artifact: https://... -->` **and** that
      `~/.claude/mwk-genie-learning.txt` holds the same URL. Two places on purpose: one survives
      the file being rewritten, the other survives the folder being deleted.
- [ ] **It asks rather than duplicating when the address is gone.** Delete both — the first line
      and the sidecar — and run it again. **It must stop and ask** whether this is the first run
      or the page went missing. If it silently publishes a new page, that is the bug this whole
      design exists to prevent, and it will not announce itself.
- [ ] **It still finds the page with only the title.** Delete both again, answer the question by
      saying the page exists, and check it recovers the right artifact by title rather than
      making a new one.
- [ ] **Step 14's how-to page publishes** and the link survives closing the terminal.
- [ ] **The show links work on the published page** — `check.sh` proves the URLs are alive, not that
      they render as clickable links once `howto.html` is an artifact. Open it and click all three.

## Needs a human reading it

- [ ] **The three questions get asked, once each.** Walk a real setup: `ccc` (step 2), admin
      access (step 7), the model (step 10). Each should be one short question with a
      recommendation, not a paragraph, and none of them should come back later.
- [ ] **Answering "no" to admin access does not silently skip anything.** It should ask again
      when it genuinely needs it, and say what for.
- [ ] **Picking the asks-every-time `ccc` is honoured.** Step 3 must check against that answer,
      not against the default.
- [ ] **`/mwk-genie:bug` shows the report before filing**, redacts the home folder path, and says
      out loud that the repo is public. **Do not test this by filing a real issue** — answer no,
      and read what it was about to send.

## Only worth doing before a release

- [ ] **Windows.** Everything above, once, in WSL. This is still the only coverage the Windows path
      has, and "everything above, once" is not enough on its own — a tester who already knows to
      open Ubuntu will open Ubuntu, and miss the thing a beginner hits first. So specifically:
- [ ] **Windows, open the terminal the way a beginner would.** Start menu or taskbar, not the Ubuntu
      entry, and check the setup notices. The default is PowerShell, where `ccc` will never exist
      and the error mentions a cmdlet. Every "restart me" step has to survive this, not just step 2.
- [ ] **Windows, the password.** At step 7, try the *Windows* sign-in password first, deliberately.
      The setup should have already told you it wants the Ubuntu one — if you find that out by
      failing three times, the warning is in the wrong place.
- [ ] **Windows, the colours actually landed.** Step 13 writes Windows Terminal's `settings.json`
      from inside WSL, across the `/mnt/c` boundary. Confirm the change is really in the file and
      really visible, not just reported. If Windows Terminal is not installed, confirm it says so
      and leaves it alone rather than improvising.
- [ ] **Windows, finding the files.** Run `explorer.exe .` from a project folder and check the
      window opens on the right place. That is the only route a Windows user has to their own work.
- [ ] **macOS.** Homebrew is expected now, for one thing only. Confirm `brew list --cask` shows
      **iTerm2 and nothing else**, and that Claude Code came from its own installer rather than a
      formula (`brew list | grep -i claude` should find nothing).
- [ ] **macOS, write down what `$TERM_PROGRAM` actually says.** Run `echo $TERM_PROGRAM` in iTerm2
      and in Apple's Terminal and record both, verbatim. Step 13 branches on `Apple_Terminal`; that
      value is corroborated by Claude Code's own binary but has never been read off a Mac. **This
      is the highest-value line on this list** — if it is wrong, step 13 either does nothing or
      talks people out of a terminal that was already fine.
- [ ] **macOS, Ctrl+J really works in Apple's Terminal.** Press it and check it starts a new line
      rather than sending. This is the claim the whole "you can decline the install" branch rests
      on, and it is now the answer we give first, on every platform.
- [ ] **macOS, brew is usable straight after installing it.** On an Apple Silicon Mac, follow step
      one exactly and confirm `brew --version` answers *before* the iTerm2 line runs. The installer
      prints a "Next steps" block that has to be run first, and skipping it is a `command not
      found` on a beginner's first command.
- [ ] **macOS, the terminal handoff.** Step one should leave them in iTerm2 before the agent is ever
      installed, so step 13 has nothing to repair. **Then test the other path on purpose:** run the
      setup from Apple's Terminal and check step 13 notices, offers rather than insists, and hands
      over cleanly to a restarted agent rather than dying silently.
- [ ] **macOS, the settings actually took.** Whatever step 13 changed in iTerm2, quit the app and
      reopen it. iTerm2 can write its preferences back on exit; a change that does not survive that
      was never made.
- [ ] **The live site still matches.** `prompts/install.md` and `prompts/setup.md` are fetched
      and published by `matewishkey.com` at build time. After a deploy, open
      `matewishkey.com/how-to/put-the-genie-in-the-box/` and check the two boxes show what this
      repo now says.
