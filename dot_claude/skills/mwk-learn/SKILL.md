---
name: mwk-learn
description: Add today to their running record of what they have learnt, across every project, from their own conversations — what they now know how to do, what went wrong and what fixed it, and the handful of things worth remembering. One file that grows, in ~/projects/learning, saved and pushed like everything else. Use when they ask what they learnt, want a summary of the day, or want something to keep.
---

<!-- requires: git gh -->

Add **today** to their record, out of what actually happened, across **every**
project — not just the one they are sitting in.

The point is not a diary. It is the page they come back to: *this is what I now
know how to do, and here is what to type.*

**It is one file, and it grows.** Not a file per day — the same file, with today
added to the top. That is what makes it worth keeping: they can see how far they
have come, and last month's fix is still there when it happens again.

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

## 3. Add today to the record

    ~/projects/learning/README.md

Plain markdown. It renders on GitHub, it prints from there, and it lives in
`~/projects` with everything else of theirs — one folder per thing they are
doing, and this is one of the things.

**The top half of that file is their howto — placed by the kit, and never yours to
touch here.** Everything above the line `## What I have learnt` stays exactly as it
is. Today goes in as a new dated entry **directly under that heading**, above every
entry already there (and replacing the *"Nothing yet"* placeholder the first time).
**Never rewrite, tidy or re-summarise a past entry** — old entries are the record,
and a record you edit is not one.

If the file is missing, the kit's copy is at
`~/projects/mwk-genie/projects/learning/create_README.md` — copy it into place
first. If the folder is not a git repo yet, `git init` it now.

Each entry is a `## <date>` heading with these sections, in this order, dropping
any that would be empty:

1. **What you can do now that you could not this morning.** The headline. One
   line each.
2. **What went wrong, and what fixed it.** Two columns. This is the part they
   will come back to.
3. **Worth remembering.** Commands, shortcuts, names of things — the bits they
   would otherwise have to ask for again. Each command in its own fenced block,
   so it copies cleanly from GitHub.
4. **Where each project got to.** One line per project touched today, so it is
   obvious what is in flight.

Rules:

- **Plain English throughout.** If a word needs explaining, explain it in the
  same sentence, once.
- **Never invent a lesson.** If today was thin, today's entry is two lines. A
  short honest entry is worth something; a padded one is worth nothing and they
  will stop opening it.
- **Never a key, a token, or a password in it** — not even a partial one. It is
  going to GitHub.

## 4. Save it, and tell them where

Commit it with today's date as the message. Push it. If the folder has nowhere to
push to yet, make it a **private** repo on GitHub and push — this is the one
folder where you do not need to ask first, because there is nothing in it but
their own notes.

Then say the one address that is theirs: the GitHub page for `learning`. That is
the one they keep.
