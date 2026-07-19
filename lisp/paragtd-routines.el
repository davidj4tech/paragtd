;;; paragtd-routines.el --- Routine scaffolding for PARA/GTD -*- lexical-binding: t; -*-

(require 'paragtd-paths)

(defconst paragtd-routines-template
  "#+title: Routines
#+filetags: routines gtd para

* Daily
** TODO Morning routine
SCHEDULED: <2026-07-20 Mon +1d>
:PROPERTIES:
:STYLE: habit
:END:
- Review calendar / hard landscape
- Check tickler and due agenda
- Choose top 3 outcomes

** TODO Evening shutdown
SCHEDULED: <2026-07-20 Mon +1d>
:PROPERTIES:
:STYLE: habit
:END:
- Clear quick capture
- Note wins and open loops
- Set up tomorrow

* Weekly
** TODO Weekly review
SCHEDULED: <2026-07-26 Sun +1w>
- Get clear: inboxes, notes, loose paper
- Get current: projects, waiting-for, tickler, calendar
- Get creative: someday/maybe and visioning

* Fortnightly
** TODO Fortnightly planning
SCHEDULED: <2026-08-02 Sun +2w>
- Review active areas
- Rebalance next actions
- Check recurring commitments

* Monthly
** TODO Monthly review
SCHEDULED: <2026-08-01 Sat +1m>
- Review areas and projects
- Check money, health, home, relationships
- Choose monthly theme

* Yearly
** TODO Yearly review
SCHEDULED: <2027-01-01 Fri +1y>
- Review the year behind
- Define the year ahead
- Refresh principles and horizons

* 5-Yearly
** TODO 5-year horizon review
SCHEDULED: <2030-01-01 Tue +5y>
- Review identity, vocation, place, relationships, body, money
- Decide what to deepen, stop, and begin

* 10-Yearly
** TODO 10-year horizon review
SCHEDULED: <2035-01-01 Mon +10y>
- Revisit life architecture
- Name the next decade's mythic arc
"
  "Default contents for `routines.org`.")

(defun paragtd-routines-install-defaults (&optional overwrite)
  "Create `routines.org` with default recurring routines.
With prefix argument OVERWRITE, replace the existing file."
  (interactive "P")
  (let ((file (paragtd-file "routines.org")))
    (when (or overwrite (not (file-exists-p file)))
      (make-directory (file-name-directory file) t)
      (with-temp-file file
        (insert paragtd-routines-template)))
    (find-file file)))

(provide 'paragtd-routines)
