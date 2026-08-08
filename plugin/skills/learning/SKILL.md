---
name: learning
description: Add today to their running record of what they have learnt, across every project, from their own conversations — what they now know how to do, what went wrong and what fixed it, and the handful of things worth remembering. One page that grows, at one address they can bookmark and print. Use when they ask what they learnt, want a summary of the day, or want something to keep.
---

Add **today** to their record, out of what actually happened, across **every**
project — not just the one they are sitting in.

The point is not a diary. It is the page they pin up: *this is what I now know
how to do, and here is what to type.*

**It is one page, and it grows.** Not a file per day — the same page, at the
same address, with today added to the top. That is what makes it worth keeping:
they can see how far they have come, and last month's fix is still there when
it happens again.

## 1. Find today's conversations

Every session is stored as JSONL, one directory per project folder:

    ~/.claude/projects/<encoded-folder-path>/<session-id>.jsonl

The directory name is their project's path with the slashes turned into dashes,
so **the folder name tells you which project a session belongs to.**

Take every file modified today, across all of those directories. If there is
nothing from today, widen to the last few days and say that is what you did.

## 2. Read them for the lesson, not the log

These files are large and most of it is machinery. **Do not read them end to
end.** You are looking for a small number of things:

- What they asked for, in their words.
- Where something **broke, and what made it work** — the error, then the fix.
  This is the most valuable thing on the page and the easiest to lose.
- Anything they had to be told twice, or asked about more than once. That is a
  thing that has not landed yet.
- Commands and shortcuts that turned out to matter.

Skip tool output, file contents and anything that only made sense in the moment.

## 3. Add today to the page

The record is a single self-contained HTML file — **a web page because a web
page prints**, and because a wall of terminal text is not something anyone
reads twice.

    ~/projects/what-we-learnt/log.html

**Read it first if it exists.** Today goes in as a new dated entry at the
**top**, above everything already there. **Never rewrite, tidy or re-summarise
a past entry** — old entries are the record, and a record you edit is not one.
If the file does not exist yet, create it with today as the only entry.

One folder, one file. `~/projects` is one folder per thing they are doing, and
a year of loose cheat sheets in there would bury the actual projects — which is
the exact confusion that folder exists to prevent.

Each entry is dated and has these sections, in this order, dropping any that
would be empty:

1. **What you can do now that you could not this morning.** The headline. One
   line each.
2. **What went wrong, and what fixed it.** Two columns. This is the part they
   will come back to.
3. **Worth remembering.** Commands, shortcuts, names of things — the bits they
   would otherwise have to ask for again.
4. **Where each project got to.** One line per project touched today, so it is
   obvious what is in flight.

Rules for the page itself:

- **Everything inline.** No links to stylesheets, no fonts, no scripts from the
  internet. It has to work on a laptop on bad hotel wifi, which is a real place
  this gets opened.
- **A print stylesheet** — `@media print` — with a white background, black text
  and no giant headers eating the first page. They will press Ctrl+P.
- **Plain English throughout.** If a word needs explaining, explain it in the
  same sentence, once.
- **Never invent a lesson.** If today was thin, today's entry is two lines. A
  short honest entry is worth something; a padded one is worth nothing and they
  will stop opening it.
- **Keep the first line of the file** exactly as described in step 4 — it is
  how you find the published page again next time.

## 4. Publish it to the same address, every time

The file on disk is the record. **The published page is its mirror, and it has
one address that never changes** — that is the whole point, because an address
that changes is not something anyone bookmarks.

**Publish `log.html` as an artifact.** To land on the same page as last time:

- **Read the first line of `log.html`.** When you publish, write the URL back
  into the file as the very first line, exactly like this, so next time you can
  find it without hunting:

      <!-- artifact: https://... -->

- **If that line is there**, publish with that URL so it updates in place.
- **If it is not** (first run, or the line was lost), list their existing
  artifacts and look for this one by title before making a new one. Only
  publish fresh if it genuinely is not there — a second copy splits the record
  in two and neither half is complete.
- **Keep the title identical between runs.** It is how the page is recognised.

Then give them the link, and **on the first run tell them to bookmark it** next
to their how-to page. On later runs just say it has been updated — they know
where it lives.

**If publishing is not available in this session, do not improvise a
workaround.** The file on disk is still the complete record, and nothing has
been lost: tell them the path, say they can double-click it, and say the link
version needs them signed in with `/login`. Next time it publishes, everything
written in the meantime goes up with it.
