;;; paragtd-zettel.el --- Reviewing zettels in the org-roam notes folder -*- lexical-binding: t; -*-

;;; Commentary:
;; The Resources half of PARA, kept as a zettelkasten: one idea per note in
;; `paragtd-zettel-directory', each linked to where it came from and to
;; concept nodes in `paragtd-zettel-concepts-directory'.
;;
;; Notes arrive as drafts tagged `inbox' — written by hand with the capture
;; template below, or distilled from agent sessions by `agent-sessions zk'
;; (those carry :ZK_STATUS: draft).  Reviewing them is the GTD inbox habit
;; applied to ideas:
;;
;;   `paragtd-zettel-review'   visit the next draft (oldest first)
;;   `paragtd-zettel-promote'  keep it: drop `inbox', mark it permanent
;;   `paragtd-zettel-discard'  delete it (a distilled note is not re-made)
;;
;; Nothing here needs org-roam loaded; the capture template is added to
;; `org-roam-capture-templates' once org-roam is.

;;; Code:

(require 'org)
(require 'paragtd-paths)

(defvar org-roam-capture-templates)

(defcustom paragtd-zettel-directory "notes"
  "Folder of permanent notes, relative to `paragtd-roam-directory'."
  :type 'string
  :group 'paragtd)

(defcustom paragtd-zettel-concepts-directory "concepts"
  "Folder of concept nodes, relative to `paragtd-roam-directory'."
  :type 'string
  :group 'paragtd)

(defcustom paragtd-zettel-inbox-tag "inbox"
  "Filetag that marks a note still waiting for review."
  :type 'string
  :group 'paragtd)

(defcustom paragtd-zettel-capture-key "z"
  "Key of the permanent-note template in `org-roam-capture-templates'."
  :type 'string
  :group 'paragtd)

(defun paragtd-zettel-dir ()
  "Absolute path of `paragtd-zettel-directory'."
  (expand-file-name paragtd-zettel-directory paragtd-roam-directory))

(defun paragtd-zettel--head (file)
  "The #+title and filetags of FILE, as (TITLE . TAGS)."
  (with-temp-buffer
    (insert-file-contents file nil 0 2048)
    (let (title tags)
      (goto-char (point-min))
      (when (re-search-forward "^#\\+title:[ \t]*\\(.*\\)$" nil t)
        (setq title (string-trim (match-string 1))))
      (goto-char (point-min))
      (when (re-search-forward "^#\\+filetags:[ \t]*\\(.*\\)$" nil t)
        (setq tags (split-string (match-string 1) ":" t "[ \t]+")))
      (cons (or title (file-name-base file)) tags))))

(defun paragtd-zettel-drafts ()
  "Draft notes, oldest first, as (TITLE . FILE)."
  (let ((dir (paragtd-zettel-dir)))
    (when (file-directory-p dir)
      (delq nil
            (mapcar (lambda (f)
                      (let ((head (paragtd-zettel--head f)))
                        (when (member paragtd-zettel-inbox-tag (cdr head))
                          (cons (car head) f))))
                    ;; Denote names start with the date, so name order is age order.
                    (sort (directory-files-recursively dir "\\.org\\'") #'string<))))))

;;;###autoload
(defun paragtd-zettel-review (&optional choose)
  "Visit the oldest draft note.  With prefix CHOOSE, pick one by title."
  (interactive "P")
  (let ((drafts (paragtd-zettel-drafts)))
    (if (null drafts)
        (message "No draft notes: the zettel inbox is empty")
      (find-file
       (if choose
           (cdr (assoc (completing-read (format "Draft (%d): " (length drafts)) drafts nil t)
                       drafts))
         (cdar drafts)))
      (message "%d draft%s — promote (keep) or discard"
               (length drafts) (if (= 1 (length drafts)) "" "s")))))

(defun paragtd-zettel--set-filetags (tags)
  "Replace the buffer's #+filetags line with TAGS."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^#\\+filetags:.*$" nil t)
        (replace-match (if tags (concat "#+filetags: :" (string-join tags ":") ":") "#+filetags:")
                       t t)
      (when tags
        (goto-char (point-min))
        (when (re-search-forward "^#\\+title:.*$" nil t)
          (end-of-line)
          (insert "\n#+filetags: :" (string-join tags ":") ":"))))))

;;;###autoload
(defun paragtd-zettel-promote ()
  "Keep the visited draft: drop the inbox tag and mark it permanent.
A Denote-style name loses its `_inbox' keyword too."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not an Org buffer"))
  (let ((tags (cdr (paragtd-zettel--head buffer-file-name))))
    (paragtd-zettel--set-filetags (delete paragtd-zettel-inbox-tag tags)))
  (save-excursion
    (goto-char (point-min))
    (when (org-at-property-drawer-p)
      (org-entry-put (point-min) "ZK_STATUS" "permanent")))
  (save-buffer)
  (let* ((old buffer-file-name)
         (new (replace-regexp-in-string
               (concat "_" (regexp-quote paragtd-zettel-inbox-tag) "\\(_\\|\\.org\\'\\)") "\\1"
               (replace-regexp-in-string
                (concat "__" (regexp-quote paragtd-zettel-inbox-tag) "\\.org\\'") ".org" old))))
    (unless (equal old new)
      (rename-file old new)
      (set-visited-file-name new t t)))
  (message "Kept: %s" (car (paragtd-zettel--head buffer-file-name))))

;;;###autoload
(defun paragtd-zettel-discard ()
  "Delete the visited draft note, after asking."
  (interactive)
  (let ((file buffer-file-name))
    (unless (and file (file-in-directory-p file (paragtd-zettel-dir)))
      (user-error "Not a note in %s" (paragtd-zettel-dir)))
    (when (yes-or-no-p (format "Delete %s? " (file-name-nondirectory file)))
      (set-buffer-modified-p nil)
      (kill-buffer)
      (delete-file file)
      (message "Discarded"))))

(defun paragtd-zettel-capture-template ()
  "The org-roam capture template for a permanent note."
  `(,paragtd-zettel-capture-key "zettel (one idea)" plain "%?"
    :target (file+head ,(concat paragtd-zettel-directory
                                "/%<%Y%m%dT%H%M%S>--${slug}__" paragtd-zettel-inbox-tag ".org")
                       "#+title: ${title}\n#+filetags: :zettel:inbox:\n\n- Source :: \n- Concepts :: \n\n")
    :unnarrowed t))

(defun paragtd-zettel--add-capture ()
  "Add the template to `org-roam-capture-templates' unless its key is taken."
  (when (and (boundp 'org-roam-capture-templates)
             (not (assoc paragtd-zettel-capture-key org-roam-capture-templates)))
    (setq org-roam-capture-templates
          (append org-roam-capture-templates (list (paragtd-zettel-capture-template))))))

(defun paragtd-setup-zettel ()
  "Install the zettel capture template (now, or once org-roam loads)."
  (with-eval-after-load 'org-roam-capture
    (paragtd-zettel--add-capture)))

(provide 'paragtd-zettel)

;;; paragtd-zettel.el ends here
