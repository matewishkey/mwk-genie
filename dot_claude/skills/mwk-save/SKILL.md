---
name: mwk-save
description: Save a session's work for someone who is not a developer — say in plain English what changed, leave a note for next time in TODO.md, make a save point, push it to GitHub, and tell them how to start fresh. Use when they say they are finished, done for now, or ask to save or back up their work.
---

They are finished for now. **Save everything and leave the place tidy for next
time.** Keep it short — this is the last thing they read, not a report.

## 1. Look at what actually changed

Check the state of the folder before you say anything about it. Read the actual
changes, not just the file names, so you can describe them in their words.

**If nothing has changed**, say so and stop. An empty save point is noise.

**If this folder is not set up for save points**, say that plainly — their work
is on their computer but nothing is keeping old versions of it — and offer to
set it up now. `/mwk-genie:new-project` is what does that for a new one.

## 2. Tell them what changed

Two or three lines, in plain English, about what is different from when they
started. What the work does now that it did not before.

Not a list of file names. Not a diff. They know what they were doing; they want
to know it landed.

## 3. Leave a note for next time

This is the part that matters, and it is why this command exists rather than
just a save point.

Write **`TODO.md`** in the project folder — a short note to whoever opens this
next, which is you, with none of this conversation in your head:

- **Where things got to.** One or two lines.
- **What is next.** Only real things: something you started and did not finish,
  something that broke, a decision they still have to make.

Rules that keep it useful:

- **Replace the file, do not add to it.** A note that only ever grows turns into
  sludge nobody reads. Anything already done comes out.
- **Plain English, no jargon**, exactly like everything else you write for them.
- **If there is genuinely nothing outstanding, say so in one line** — or delete
  the file if it exists. An empty list is a better handover than an invented one.

Then tell them, in one line, that the note is there. That is what makes the next
step safe.

## 4. Make the save point

Commit everything, `TODO.md` included, with a message that says what changed in
normal words. No prefixes, no tags, no conventions — a sentence a human would
write.

## 5. Push it to GitHub

So there is a copy that is not on their laptop, and so the note travels with it.

If the folder has nowhere to push to, say so and offer to put it on GitHub now —
private. Do not do it without asking.

## 6. How to come back, and how to start fresh

Print these on their own lines, with a blank line above and below:

    cd ~/projects/<folder name>
    ccc

...opens this project again, from any terminal window. You will read `TODO.md`
when you get there, so they can start the next session by saying "carry on".

    /clear

...starts a fresh conversation. Tell them what it actually does, because the
word is alarming: **it makes you forget this conversation, not their work.**
Their work is saved, pushed, and the note is written down — this only empties
your head so the next thing starts clean and fast.

Mention the context bar in passing if it is looking full. That is the thing
`/clear` fixes.
