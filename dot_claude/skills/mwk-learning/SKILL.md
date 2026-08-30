---
name: mwk-learning
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

    ~/mwk/site/learnt.html

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

### What it looks like

**This page carries the Mate Wish Key look, in its lightest form.** It and the
bookmark page are the two things they keep, so they should read as a pair
rather than as one designed page and one plain one.

**Before you write it, read <https://matewishkey.com/design/>.** That page
renders the real colour tokens live, so it cannot go stale the way a copy in
this file would. Take the values from there. If it is unreachable, use what is
already in `learnt.html` from last time and say so in a line.

Keep it minimal — this is a record, not a brochure. Three rules, and they are
the same three the bookmark page follows:

- **Red is spent once**, on the block at the top left, and nowhere else. The
  block reads as loud because of how much quiet page is around it, so a second
  red spend costs the first its effect.
- **Red is never body text.** Paragraphs are `--ink`, captions `--mute`,
  kickers `--faint`. **The copy buttons are deliberately not red.**
- **The block is the real logo file**, inlined verbatim from
  `matewishkey.com/favicon.svg`. Do not hand-build a red square with a mark in
  it. `~/projects/mwk-genie/mwk/site/index.html` has the correct one inlined
  already — copy it from there rather than drawing one.

Display type is Fraunces, body is Manrope, with ordinary system fallbacks
because the page must work with no network. Entries are separated by a rule, not
boxed in cards.

Rules for the page itself:

- **Everything inline.** No links to stylesheets, no fonts, no scripts from the
  internet. It has to work on a laptop on bad hotel wifi, which is a real place
  this gets opened.
- **A copy button on every command.** Section 3 is a list of things to type,
  and a thing to type is worth nothing if they have to select it by hand in a
  browser and get the leading spaces with it. One button per command block,
  labelled `Copy`, that says `Copied` for a moment afterwards so they know it
  worked. Use `navigator.clipboard.writeText` with a `document.execCommand`
  fallback, and copy the **plain text** of the command — not the HTML around
  it. An inline `<script>` is fine and is not what "nothing from the internet"
  above is about.
- **A print stylesheet** — `@media print` — with a white background, black text
  and no giant headers eating the first page. They will press Ctrl+P. **Hide
  the copy buttons in print** (`@media print { .copy { display: none } }`) — a
  button on paper is a smudge.
- **Plain English throughout.** If a word needs explaining, explain it in the
  same sentence, once.
- **Never invent a lesson.** If today was thin, today's entry is two lines. A
  short honest entry is worth something; a padded one is worth nothing and they
  will stop opening it.
- **Keep the first line of the file** exactly as described in step 4 — it is
  half of how you find the published page again next time, and rewriting the
  file without it is how the record ends up at two addresses.

## 4. Save it, and tell them where

Write it to `~/mwk/site/learnt.html`, beside `index.html`. Their page is already
being served, so it is at **http://127.0.0.1:29200/learnt.html** the moment you
save it. Say that address out loud — it is the one they keep.

**There is no publishing step and there is nothing to look up.** This used to be
an artifact at an address that had to be stored in three places, because a second
page looked exactly like a successful run. A file cannot split in two, so all of
that is gone. Do not reintroduce it.

If `~/mwk/site/` does not exist, the kit was never installed here — say so rather
than inventing somewhere else to put it.
