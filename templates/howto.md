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

## The things it does for you

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

Adds today to a running page of what you now know how to do, what went wrong
and what fixed it. **Same page every time**, newest at the top — so it turns
into a record of the whole thing, not a pile of separate notes. Bookmark it
alongside this one. You can print it.

### Something in the genie itself is broken

> "report this bug"

or `/mwk-genie:bug`

Writes the report for you out of what actually just happened — the error, what
you were doing, which computer you are on — shows it to you, and only files it
if you say yes. **It goes to a public place**, so your report and your GitHub
name can be seen by anyone. It will remind you of that before it sends.

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

## Switching to the stronger brain

```
/model opus
```

There are two. **Sonnet** is the fast one and your plan stretches much further
on it — that is what you are on unless you changed it. **Opus** is stronger at
genuinely hard problems and uses your allowance up faster.

This switches it **for the conversation you are in**, not forever. `/model
sonnet` puts it back. Worth reaching for when something has you both stuck;
not worth leaving on.

---

## Two things that will scare you

**Typing your computer password shows nothing.** No dots, no stars, nothing
moves. It is working. Type it and press enter. Do not type it again.

**It probably does not ask before each command.** During setup you picked one
of two: getting on with the work once you have agreed to it in conversation, or
stopping to ask before every single command. Most people pick the first, and
that is the trade that makes this a your-own-computer thing and not a work one.

To change your mind, open the file `ccc` lives in — `~/.zshrc` on a Mac,
`~/.bashrc` on Windows or Linux — find the two lines near the bottom that both
start with `alias ccc=`, and move the `#` to the other one. Open a new terminal
window and it has changed. Or just ask: *"switch ccc to the other one."*

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

---

## Where this came from, and what it is for

**Mate Wish Key** — a show about sitting down with a complete stranger for a
few hours and building the thing they wished their computer did.

Everything you just set up is the box. **The point is doing it together.**

### [Come on the show →](https://matewishkey.com/show)

You, me and the agent. You bring the thing you wish your computer did, we make
it, and we talk about you and me while it happens. About three hours.

**You do not need to be any good at this.** That is the whole premise — the
question the show is asking is whether a stranger can learn to build things in
an afternoon. You are already further along than the last person who started.

Want to watch one first? Fair enough:

| | |
|---|---|
| **[YouTube](https://www.youtube.com/@matewishkey)** | whole shows, start to finish |
| **[Twitch](https://www.twitch.tv/matewishkey)** | live, while it is actually happening |
