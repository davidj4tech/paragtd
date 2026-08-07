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

## Files

- `lisp/paragtd.el` - package entrypoint
- `lisp/paragtd-paths.el` - Org directories, agenda files, custom agenda views
- `lisp/paragtd-capture.el` - capture templates and tickler helper
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
bin/paragtd-astro-generate --year 2026 --output ~/org/astro.org --timezone Australia/Melbourne
```

It currently generates precise alerts, scheduled in Melbourne time by default,
for new moons, full moons, sun sign ingresses, sun decans, Aries ingress /
astrological year, and moon sign ingresses. Each entry also stores the UTC time
as an Org property.

## License

GPL-3.0-or-later — see [COPYING](COPYING).
