---
name: save
description: Save a session's work for someone who is not a developer — say in plain English what changed, make a save point, push it to GitHub, flag anything left half-done, and tell them how to start fresh. Use when they say they are finished, done for now, or ask to save or back up their work.
---

They are finished for now. **Save everything and tell them where things stand.**
Keep it short — this is the last thing they read, not a report.

## 1. Look at what actually changed

Check the state of the folder before you say anything about it. Read the actual
changes, not just the file names, so you can describe them in their words.

**If nothing has changed**, say so and stop. An empty save point is noise.

**If this folder is not set up for save points**, say that plainly — their work
is on their computer but nothing is keeping old versions of it — and offer to
set it up now. `/tmwks:new-project` is what does that for a new one.

## 2. Tell them what changed

Two or three lines, in plain English, about what is different from when they
started. What the work does now that it did not before.

Not a list of file names. Not a diff. They know what they were doing; they want
to know it landed.

## 3. Make the save point

Commit everything, with a message that says what changed in normal words. No
prefixes, no tags, no conventions — a sentence a human would write.

## 4. Push it to GitHub

So there is a copy that is not on their laptop.

If the folder has nowhere to push to, say so and offer to put it on GitHub now —
private. Do not do it without asking.

## 5. Anything left hanging

One or two lines, only if there is something real: a thing you started and did
not finish, something that broke, a decision they still have to make. Say it now
so it is not a surprise next time.

If there is nothing, say nothing.

## 6. How to come back, and how to start fresh

Print these on their own lines, with a blank line above and below:

    ccc <folder name>

...opens this project again, from any terminal window.

    /clear

...starts a fresh conversation. Tell them what it actually does, because the
word is alarming: **it makes you forget this conversation, not their work.**
Their work is saved and on GitHub — this only empties your head so the next
thing starts clean and fast.

Mention the context bar in passing if it is looking full. That is the thing
`/clear` fixes.
