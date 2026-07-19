# paragtd

Portable Org workflow package for Ryder's PARA/GTD system.

This package owns the reusable workflow code. Editor-specific repos, such as
`spacemacs-config`, should only adapt/load it.

## Scope

- GTD/PARA Org paths and agenda files
- Core capture templates and tickler refiling
- Recurring daily, weekly, fortnightly, monthly, yearly, 5-yearly, and 10-yearly routines
- Astrological and lunar alert generation hooks

## Files

- `lisp/paragtd.el` - package entrypoint
- `lisp/paragtd-paths.el` - Org directories, agenda files, custom agenda views
- `lisp/paragtd-capture.el` - capture templates and tickler helper
- `lisp/paragtd-routines.el` - routine scaffolding
- `lisp/paragtd-astro.el` - Emacs wrapper for astro generation
- `bin/paragtd-astro-generate` - Python generator for `astro.org`

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
python3 -m venv .venv
.venv/bin/pip install kerykeion
bin/paragtd-astro-generate --year 2026 --output ~/org/astro.org --timezone Australia/Melbourne
```

It currently generates precise alerts, scheduled in Melbourne time by default,
for new moons, full moons, sun sign ingresses, sun decans, Aries ingress /
astrological year, and moon sign ingresses. Each entry also stores the UTC time
as an Org property.
