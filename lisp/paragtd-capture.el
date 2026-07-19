;;; paragtd-capture.el --- PARA/GTD Org capture templates -*- lexical-binding: t; -*-

(require 'paragtd-paths)

(defun paragtd-refile-to-tickler ()
  "Move the current subtree to the tickler file and prompt for a schedule date."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an Org buffer"))
  (org-back-to-heading t)
  (let* ((beg (point))
         (end (save-excursion (org-end-of-subtree t t)))
         (subtree (buffer-substring-no-properties beg end))
         (tickler-file (paragtd-file "tickler.org")))
    (delete-region beg end)
    (save-buffer)
    (with-current-buffer (find-file-noselect tickler-file)
      (org-mode)
      (goto-char (point-min))
      (unless (re-search-forward "^\\* Tickler$" nil t)
        (goto-char (point-max))
        (unless (bolp)
          (insert "\n"))
        (insert "* Tickler\n"))
      (org-end-of-subtree t t)
      (unless (bolp)
        (insert "\n"))
      (let ((start (point)))
        (insert subtree)
        (goto-char start)
        (org-back-to-heading t)
        (org-schedule nil))
      (save-buffer))))

(defun paragtd-capture-templates ()
  "Return core GTD capture templates."
  `(("t" "Todo" entry (file ,(paragtd-file "inbox.org"))
     "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n")
    ("n" "Next action" entry (file+headline ,(paragtd-file "next-actions.org") "Inbox")
     "* NEXT %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n")
    ("w" "Waiting for" entry (file+headline ,(paragtd-file "waiting-for.org") "Waiting")
     "* WAITING %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n")
    ("k" "Tickler / defer until" entry (file+headline ,(paragtd-file "tickler.org") "Tickler")
     "* TODO %?\nSCHEDULED: %^T\n:PROPERTIES:\n:CREATED: %U\n:END:\n")
    ("j" "Journal entry" entry (file+olp+datetree ,(paragtd-file "journal.org"))
     "* %U %?\n" :tree-type week)))

(defvar paragtd-capture-extra-templates nil
  "Extra `org-capture-templates' entries appended after the core GTD set.
Set this before Org loads (or re-run `paragtd-setup-capture') to add
site-local templates without modifying the package.")

(defun paragtd-setup-capture ()
  "Install PARA/GTD capture helpers."
  (with-eval-after-load 'org
    (define-key org-mode-map (kbd "C-c k") #'paragtd-refile-to-tickler)
    (setq org-capture-templates (append (paragtd-capture-templates)
                                        paragtd-capture-extra-templates))))

(provide 'paragtd-capture)
