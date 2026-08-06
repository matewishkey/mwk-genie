---
name: new-project
description: Start a new project for someone who is not a developer — a folder in ~/projects, save points turned on, a private GitHub repo, and one line telling them how to come back to it. Use when they say they want to start something new, or want to work on a thing that does not exist yet.
argument-hint: "[what it is for]"
---

They want to start something new. **Do all of this for them** — do not hand them
commands to type.

The argument, if there is one, is what the project is for: `$ARGUMENTS`

## 1. What is it for

If they did not say, ask **one** question: what do they want this project to do?
One sentence back from them is enough. Do not interview them.

## 2. Pick a name

Turn their answer into a short folder name — lowercase, hyphens instead of
spaces, two or three words at most. `holiday-photos`, not
`my-holiday-photos-project-2026`.

Show them the name you picked and let them change it. One line, not a debate.

If `~/projects/<name>` already exists, say so and pick another rather than
writing into it.

## 3. Make it

- `mkdir -p ~/projects/<name>` and work there from now on.
- Write a `README.md` in it: a title and the one sentence they gave you. That
  is all it needs today. It gives them something to open and something for the
  first save point to hold.

## 4. Turn on save points

`git init`, then a first commit.

Say what it buys them, **in one sentence, once**: from now on every version of
their work is kept, so trying something and hating it costs nothing. Do not
explain git. Do not use the words *repository*, *commit* or *branch* without
saying what they mean in the same sentence.

## 5. Put it on GitHub

A private repo, pushed, using the official GitHub command-line tool — check its
own help rather than reciting flags from memory.

**Private unless they ask otherwise.** Say that out loud, because "on the
internet" is the bit that worries people.

If they are not signed in to GitHub on this machine, or the tool is not
installed, do not derail the whole thing: say the folder and save points are
working, that the GitHub copy is missing, and offer to sort it now or later.

## 6. Show them it worked

Show the folder path, and that the first save point and the GitHub copy exist.
"Done" on its own is not done.

## 7. Tell them the two things they need to remember

Print these on their own lines, with a blank line above and below:

    ccc <name>

...from any terminal window, opens this project again. That is the whole way
back — they never have to know where the folder is.

    /mwk-genie:save

...when they are finished for now. It writes down what changed and puts it
somewhere safe. Tell them they can also just say "save my work" — the slash
command and the sentence do the same thing.

## 8. Then get on with it

Ask what they actually want to do first. That is the thing they came for.
Everything above was only the folder.
