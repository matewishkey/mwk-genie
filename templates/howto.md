# How to work with your genie

**Bookmark this page.** It is the only thing you need to remember, and you do not
need to remember any of it — it is all here.

---

## Starting it

Open a terminal window and type three letters:

```
ccc
```

That is it. It starts wherever you are standing, which is why the next bit
matters.

---

## Knowing where you are

Your prompt — the bit before you type — tells you:

```
~/projects/holiday-photos (main*) $
```

- `~/projects/holiday-photos` — the folder you are in.
- `(main)` — this folder is on GitHub.
- `*` — **you have work that is not saved yet.** When the star is gone,
  everything is safe.

Three commands move you around. They are the only ones worth learning:

| Type this | It does |
|---|---|
| `cd projects` | go into a folder |
| `cd ..` | go back up one |
| `ls` | show what is in this folder |

So to open a project you already have:

```
cd ~/projects/holiday-photos
```
```
ccc
```

---

## The four things it does for you

You can **type** these, or just **say them in normal words**. Both work.

### Starting something new

> "start me a new project"

or `/mwk-genie:new-project`

Makes a folder, sets up saving, and puts a private copy on GitHub — private
means only you can see it. It ends by telling you exactly how to come back.

### Finishing for now

> "save my work"

or `/mwk-genie:save`

Tells you what changed in plain English, writes a note to next time, saves it,
and puts it somewhere safe. **Do this before you close the laptop.**

### A second opinion

> "how are we doing"

or `/mwk-genie:magic`

Steps back and looks at the whole thing with fresh eyes: what is this actually
for, and has it wandered off. It tells you the two or three things worth fixing
now, and stays quiet about the rest.

### What you learnt today

> "what did I learn today"

or `/mwk-genie:learning`

Builds you a page of what you now know how to do, what went wrong and what
fixed it. It opens in your browser and you can print it.

---

## Starting a fresh conversation

```
/clear
```

**It forgets the conversation, not your work.** Your files and your saved
versions stay exactly where they are.

Do it whenever you start something different, or when the bar showing how full
its memory is starts looking full. A fresh conversation is faster and sharper
than a long one.

---

## Two things that will scare you

**Typing your computer password shows nothing.** No dots, no stars, nothing
moves. It is working. Type it and press enter. Do not type it again.

**It does not ask before each command.** You agree to the work in conversation
— it says what it is going to do, you say yes — and then it gets on with it
instead of stopping at every step. That is the trade, and it is why this belongs
on your own computer and not a work one.

---

## Changing how it behaves

There is a file at:

```
~/.claude/CLAUDE.md
```

It is written in plain English and **it is yours**. If something it does annoys
you, open that file, change the line, and it does it differently from then on.
That is the whole mechanism — no settings screen, no support ticket.

Do not want to edit it yourself? Say *"add a rule to my CLAUDE.md that…"* and it
will do it for you.

---

## When something goes wrong

- **Paste the error back to it.** Copy whatever red text you got, paste it in,
  and let it work it out. This is the single most useful habit you can have.
- **Take a screenshot and paste that in.** It can see pictures.
- **Ask what a command does** before you say yes. That question is never
  annoying and never a waste of time.
