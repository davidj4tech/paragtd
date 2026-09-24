;;; paragtd-paths.el --- PARA/GTD Org paths and agenda views -*- lexical-binding: t; -*-

(defgroup paragtd nil
  "PARA/GTD workflow helpers."
  :group 'org)

(defcustom paragtd-org-directory "~/org"
  "Root directory for operational Org files."
  :type 'directory
  :group 'paragtd)

(defcustom paragtd-roam-directory "~/org/roam"
  "Root directory for org-roam notes."
  :type 'directory
  :group 'paragtd)

(defcustom paragtd-core-files
  '("inbox.org"
    "next-actions.org"
    "waiting-for.org"
    "someday.org"
    "tickler.org"
    "areas.org"
    "journal.org"
    "projects.org"
    "visioning.org"
    "routines.org"
    "lunar.org")
  "Org files that make up the operational agenda surface."
  :type '(repeat string)
  :group 'paragtd)

(defcustom paragtd-todo-keywords
  '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "|" "DONE(d!)" "CANCELLED(c@)"))
  "TODO keywords for the PARA/GTD system.
NEXT and WAITING are emitted by the capture templates, so Org has to
know them; without this they are just part of the heading text."
  :type 'sexp
  :group 'paragtd)

(defun paragtd-file (name)
  "Return absolute path for Org file NAME under `paragtd-org-directory`."
  (expand-file-name name paragtd-org-directory))

(defun paragtd-agenda-files ()
  "Return the agenda files for the PARA/GTD system."
  (mapcar #'paragtd-file paragtd-core-files))

(defcustom paragtd-astro-stale-days 2
  "Days after which a past astro alert is skipped in agenda views.
Astro alerts are point-in-time and never marked DONE, so without this
every past entry lingers as overdue."
  :type 'integer
  :group 'paragtd)

(defun paragtd-astro-skip-stale ()
  "Skip astro.org entries scheduled more than `paragtd-astro-stale-days` ago.
For use as `org-agenda-skip-function-global'; leaves other files alone."
  (when (and buffer-file-name
             (string= (file-name-nondirectory buffer-file-name) "astro.org"))
    (let ((sched (org-entry-get nil "SCHEDULED")))
      (when (and sched
                 (< (org-time-stamp-to-now sched)
                    (- paragtd-astro-stale-days)))
        (org-entry-end-position)))))

(defun paragtd-setup-paths ()
  "Install Org paths and custom agenda commands."
  (setq org-directory paragtd-org-directory
        org-roam-directory paragtd-roam-directory
        org-todo-keywords paragtd-todo-keywords
        org-agenda-files (paragtd-agenda-files)
        org-agenda-skip-function-global #'paragtd-astro-skip-stale)
  (setq org-agenda-custom-commands
        `(("k" "Tickler review"
           ((agenda ""
                    ((org-agenda-overriding-header "Tickler review")
                     (org-agenda-span 30)
                     (org-agenda-files (list ,(paragtd-file "tickler.org")))))))
          ("r" "Routines"
           ((agenda ""
                    ((org-agenda-overriding-header "Routines")
                     (org-agenda-span 14)
                     (org-agenda-files (list ,(paragtd-file "routines.org")
                                             ,(paragtd-file "lunar.org")))))))
          ;; "A", not "a": "a" would shadow the default day/week agenda
          ("A" "Astro alerts"
           ((agenda ""
                    ((org-agenda-overriding-header "Astro alerts")
                     (org-agenda-span 45)
                     (org-agenda-files (list ,(paragtd-file "astro.org"))))))))))

(provide 'paragtd-paths)
