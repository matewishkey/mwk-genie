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
- [ ] **Step 14's how-to page publishes** and the link survives closing the terminal.

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

- [ ] **Windows.** Everything above, once, in WSL — the Ubuntu-in-Windows path is the one nobody
      runs by accident, and step 13 (terminal colours) only exists there.
- [ ] **macOS.** Confirm no Homebrew got installed. It should not have; the agent has its own
      installer and never needed a package manager.
- [ ] **The live site still matches.** `prompts/install.md` and `prompts/setup.md` are fetched
      and published by `matewishkey.com` at build time. After a deploy, open
      `matewishkey.com/wishes/put-the-genie-in-the-box` and check the two boxes show what this
      repo now says.
