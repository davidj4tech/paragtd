# paragtd

Portable Org workflow package for a PARA/GTD system: paths and agenda views,
capture templates, recurring routines, and astrological/lunar alerts.

This package owns the reusable workflow code and works in any Emacs (no
Spacemacs/Doom dependency). Editor-specific configs should only adapt/load it;
site-local capture templates can be appended via
`paragtd-capture-extra-templates` without modifying the package.

## Scope

- GTD/PARA Org paths and agenda files
- Core capture templates and tickler refiling
- Recurring daily, weekly, fortnightly, monthly, yearly, 5-yearly, and 10-yearly routines
- Astrological and lunar alert generation hooks
- Sequenced projects: step-by-step blocking, and Gantt-style dates via org-edna

## Files

- `lisp/paragtd.el` - package entrypoint
- `lisp/paragtd-paths.el` - Org directories, agenda files, custom agenda views
- `lisp/paragtd-capture.el` - capture templates and tickler helper
- `lisp/paragtd-sequence.el` - sequenced projects (task dependencies)
- `lisp/paragtd-export.el` - `.paragtd.json`, the setup described for tools outside Emacs
- `bin/paragtd-export` - write it from a batch Emacs (paragtd's defaults only)
- `lisp/paragtd-routines.el` - routine scaffolding
- `lisp/paragtd-astro.el` - Emacs wrapper for astro generation
- `bin/paragtd-astro-generate` - Python generator for `astro.org`

## Bootstrap

```sh
bin/bootstrap
bin/test
```

`bin/bootstrap` creates the repo-local virtualenv, installs Kerykeion, and runs
basic Python/Emacs smoke checks.

## Emacs Usage

```elisp
(add-to-list 'load-path "~/projects/paragtd/lisp")
(require 'paragtd)
(paragtd-setup)
```

Useful commands:

- `paragtd-routines-install-defaults`
- `paragtd-astro-generate-year`

## Astro Notes

The generator uses Kerykeion/pyswisseph from the repo-local virtualenv when
available:

```sh
bin/bootstrap
bin/paragtd-astro-generate --year 2026 --output ~/org/astro.org \
  --lunar-output ~/org/lunar.org --timezone Australia/Melbourne
```

It currently generates precise alerts, scheduled in Melbourne time by default,
for new moons, full moons, sun sign ingresses, sun decans, Aries ingress /
astrological year, and moon sign ingresses. Each is a plain heading with an
active timestamp rather than a scheduled TODO, so it shows in the agenda on its
day and never lingers as overdue. Each entry also stores the UTC time as an Org
property.

`astro.org` is not an agenda file: it holds a few hundred alerts a year, and
has its own agenda view (`A`, the next 45 days). With `--lunar-output`, the new
and full moon routines, the ones that ask for a check-in, go to `lunar.org`
instead, which is in the agenda and in the Routines view (`r`).

## License

GPL-3.0-or-later — see [COPYING](COPYING).

## Sequenced projects

A project can run its steps in order, with each step's start date derived
from when the previous one was actually finished — the Gantt idea of
"successor starts when its predecessor completes, plus lag".

This works in two layers, and the first needs no external package:

- **Blocking** is plain Org. `paragtd-setup` turns on
  `org-enforce-todo-dependencies` and `org-agenda-dim-blocked-tasks`, and a
  project with `:ORDERED: t` will not let a step close while an older
  sibling is open.
- **Dating** is [org-edna](https://elpa.gnu.org/packages/org-edna.html),
  which is optional. paragtd never installs it; if the package is on the
  load path, `paragtd-setup` enables `org-edna-mode`. Each step then carries
  a `:TRIGGER:` that schedules the next one when it is marked DONE.

Use `M-x paragtd-sequence-subtree` (`C-c s`) on a project heading to stamp
an existing subtree, or the `p` capture template for a new one. A prefix
argument prompts for the lag in days; the default is
`paragtd-sequence-default-lag`. `paragtd-sequence-unsequence` undoes it.

The generated trigger looks like:

    :TRIGGER: next-sibling todo!(NEXT) scheduled!("++2d")

`++Nd` is deliberate. org-edna reads a single `+` (and the Org repeater
`.+`) as an increment of an existing timestamp and errors with "Tried to
increment a non-existent timestamp" when the step has no date yet, which is
the normal case. `++` is measured from now instead.

Only forward propagation is possible: finishing a step dates its successor.
Org cannot work a Gantt chart backwards from an end date to derive starts.

## TODO keywords

`paragtd-todo-keywords` defines `TODO/NEXT/WAITING/DONE/CANCELLED`. The
capture templates emit `NEXT` and `WAITING`, and until Org is told about
them it treats them as ordinary heading text rather than states.

## Outside Emacs

`paragtd-setup` writes `.paragtd.json` at the top of the Org directory once
startup has finished. It lists the core files, the TODO keywords, the capture
templates (only those with a literal string template and a file target), the
sequencing defaults and the astro settings, as this Emacs has them, including
site templates. A tool that reads the tree without Emacs can take the layout
from it rather than copying paragtd's defaults. agent-media's Organiser, the
phone app, does this.

The file is only rewritten when its content changes. It sits in the tree, so
whatever syncs the tree carries it to other hosts. `M-x paragtd-export`
writes it on demand, and setting `paragtd-export-file` to nil turns it off.
On a host with no Emacs session, `bin/paragtd-export` writes paragtd's
defaults from a batch Emacs.
