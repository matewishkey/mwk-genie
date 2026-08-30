# Starter websites

Two of them. Copy one into a project instead of starting from an empty file — a blank page is
where people stall, and inventing a layout is not the interesting part of what they came to do.

```
mwk.css       the master copy — edit this one
one-page/     index.html  mwk.css          everything on one scrolling page
pages/        index.html  work.html  about.html  mwk.css     a small site with a menu
```

**Each template ships its own copy of `mwk.css`** so that copying one folder gives a site that
works, with nothing to wire up. The copy at the top is the master: change it there, then copy it
down into both. They are meant to be identical, and `check.sh` says so if they drift.

**Start with `one-page/`.** Almost every first website is one page, and splitting it later is
five minutes' work. Reach for `pages/` only when there is genuinely more than one thing to say.

## The structure, and why it is this shape

**Plain HTML and one stylesheet. No build step, nothing to install, nothing to keep up to date.**
Open `index.html` in a browser and it works — from a folder, from a USB stick, from anywhere.
That is worth more to someone learning than any framework, because when something breaks there is
only one place it can be.

**`mwk.css` is the whole look, and the top of it is the whole look's settings.** Colours, widths
and the font are named once at the top and used by name everywhere below. Change `--brand` and the
site changes with it. Nothing else needs to know.

**The header is copied into each page in `pages/`, not shared.** That is deliberate: sharing it
means a build step or JavaScript, and with three pages the copy is genuinely easier. If it ever
gets to ten pages, that is the moment to reach for something else — not before.

## Making it theirs

The values in `mwk.css` are Mate Wish Key's own. **They are a starting point, not a rule** — the
thing worth keeping is not the red, it is the habit of naming a colour once at the top instead of
scattering it through the file.

Two things to change before showing anyone: the `<title>` and the `<meta name="description">` at
the top of each page. They are what appears in a search result and when the link is shared, and
they are the two people most often forget.

## Where the design came from

Each template's footer has a commented-out line crediting Mate Wish Key. **It is commented out on
purpose** — putting our name on a stranger's website by default would be presumptuous, and nothing
anywhere checks whether they turn it on. It is there so that someone who wants to say where it came
from does not have to work out how.

## Seeing it

Any project folder can be served on its own address — `mwk port` inside the folder gives its
number, and it is the same number every time.
