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
    "astro.org")
  "Org files that make up the operational agenda surface."
  :type '(repeat string)
  :group 'paragtd)

(defun paragtd-file (name)
  "Return absolute path for Org file NAME under `paragtd-org-directory`."
  (expand-file-name name paragtd-org-directory))

(defun paragtd-agenda-files ()
  "Return the agenda files for the PARA/GTD system."
  (mapcar #'paragtd-file paragtd-core-files))

(defun paragtd-setup-paths ()
  "Install Org paths and custom agenda commands."
  (setq org-directory paragtd-org-directory
        org-roam-directory paragtd-roam-directory
        org-agenda-files (paragtd-agenda-files))
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
                     (org-agenda-files (list ,(paragtd-file "routines.org")))))))
          ("a" "Astro alerts"
           ((agenda ""
                    ((org-agenda-overriding-header "Astro alerts")
                     (org-agenda-span 45)
                     (org-agenda-files (list ,(paragtd-file "astro.org"))))))))))

(provide 'paragtd-paths)
