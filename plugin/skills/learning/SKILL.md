---
name: learning
description: Build a cheat sheet of what they learnt today, across every project, from their own conversations — what they now know how to do, what went wrong and what fixed it, and the handful of things worth remembering. Written as a web page they can read and print. Use when they ask what they learnt, want a summary of the day, or want something to keep.
---

Make them a cheat sheet of **today**, out of what actually happened, across
**every** project — not just the one they are sitting in.

The point is not a diary. It is the page they pin up: *this is what I now know
how to do, and here is what to type.*

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

## 3. Write the cheat sheet

A single self-contained HTML file — **it is a web page because a web page
prints**, which is what they asked for, and because a wall of terminal text is
not something anyone reads twice.

Write it to:

    ~/projects/what-we-learnt/<YYYY-MM-DD>.html

**One folder, not a loose file per day.** `~/projects` is one folder per thing
they are doing, and a year of cheat sheets sitting in it would bury the actual
projects — which is the exact confusion that folder exists to prevent.

Sections, in this order, and drop any that would be empty:

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
- **Never invent a lesson.** If today was thin, the page is short. A short
  honest page is worth something; a padded one is worth nothing and they will
  not open the next one.

## 4. Hand it over

Tell them the file path, and try to open it in their browser with whatever the
machine has — `open` on a Mac, `xdg-open` on Linux, `explorer.exe` on Windows
WSL. **If none of them works, do not make it a problem:** tell them to
double-click the file. Print is Ctrl+P once it is open.
