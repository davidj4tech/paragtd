;;; paragtd-export.el --- Describe the setup for tools outside Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; Writes `.paragtd.json' at the top of `paragtd-org-directory': the core
;; files, the TODO keywords, the capture templates, the sequencing
;; defaults and the astro settings, as this Emacs has them.  Tools that
;; read the Org tree without Emacs (agent-media's Organiser, for one) take
;; the layout from it instead of copying paragtd's defaults by hand, so a
;; site's own keywords or templates reach them too.
;;
;; The file sits in the tree it describes, so whatever syncs the tree
;; carries it to other hosts.  It is rewritten when its content changes,
;; once startup has finished (site templates are often added after
;; `paragtd-setup'), and on demand with `M-x paragtd-export'.

;;; Code:

(require 'json)
(require 'paragtd-paths)
(require 'paragtd-capture)
(require 'paragtd-sequence)
(require 'paragtd-astro)

(defcustom paragtd-export-file ".paragtd.json"
  "File name, under `paragtd-org-directory', the description is written to.
Nil turns the export off."
  :type '(choice (const :tag "Off" nil) string)
  :group 'paragtd)

(defconst paragtd-export-version 1
  "Bumped when a field changes meaning.")

(defun paragtd-export--relative (file)
  "FILE relative to the Org directory when it is inside it."
  (let ((abs (expand-file-name file paragtd-org-directory)))
    (if (file-in-directory-p abs paragtd-org-directory)
        (file-relative-name abs (expand-file-name paragtd-org-directory))
      abs)))

(defun paragtd-export--template (tpl)
  "An alist describing capture template TPL, or nil to leave it out.
Prefix entries (a key and a description only), targets other than a
file, and templates that are not a literal string are left out: a tool
outside Emacs cannot evaluate them."
  (pcase tpl
    (`(,key ,desc ,type ,target ,(and (pred stringp) body) . ,props)
     (let ((file (and (consp target) (stringp (nth 1 target)) (nth 1 target))))
       (when file
         `((key . ,key)
           (label . ,desc)
           (type . ,(symbol-name type))
           (target . ,(symbol-name (car target)))
           (file . ,(paragtd-export--relative file))
           ,@(when (eq (car target) 'file+headline)
               `((headline . ,(nth 2 target))))
           ,@(when (plist-get props :tree-type)
               `((tree_type . ,(symbol-name (plist-get props :tree-type)))))
           ,@(when (plist-get props :prepend) '((prepend . t)))
           (template . ,body)))))))

(defun paragtd-export--keywords ()
  "Each TODO sequence as a vector of words, fast-access keys kept."
  (vconcat (mapcar (lambda (seq) (vconcat (if (consp seq) (cdr seq) (list seq))))
                   (if (boundp 'org-todo-keywords) org-todo-keywords paragtd-todo-keywords))))

(defun paragtd-export-manifest ()
  "The description, as an alist ready for `json-encode'."
  (let ((templates (if (and (boundp 'org-capture-templates) org-capture-templates)
                       org-capture-templates
                     (append (paragtd-capture-templates) paragtd-capture-extra-templates))))
    `((version . ,paragtd-export-version)
      (org_directory . ,(abbreviate-file-name (expand-file-name paragtd-org-directory)))
      (roam_directory . ,(paragtd-export--relative paragtd-roam-directory))
      (files . ,(vconcat paragtd-core-files))
      (todo_keywords . ,(paragtd-export--keywords))
      (capture . ,(vconcat (delq nil (mapcar #'paragtd-export--template templates))))
      (sequence . ((next_keyword . ,paragtd-sequence-next-keyword)
                   (default_lag_days . ,paragtd-sequence-default-lag)))
      (astro . ((generator . ,paragtd-astro-generator-command)
                (timezone . ,paragtd-astro-timezone)
                (stale_days . ,paragtd-astro-stale-days))))))

;;;###autoload
(defun paragtd-export (&optional file)
  "Write the description to FILE (default: `paragtd-export-file' in the Org
directory) if it changed.  Return the file name, or nil when off or when
the Org directory does not exist."
  (interactive)
  (let ((file (or file
                  (and paragtd-export-file
                       (file-directory-p paragtd-org-directory)
                       (expand-file-name paragtd-export-file paragtd-org-directory)))))
    (when file
      (let* ((json-encoding-pretty-print t)
             (text (concat (json-encode (paragtd-export-manifest)) "\n")))
        (unless (and (file-readable-p file)
                     (string= text (with-temp-buffer
                                     (insert-file-contents file)
                                     (buffer-string))))
          (with-temp-file file (insert text)))
        (when (called-interactively-p 'interactive)
          (message "Wrote %s" file))
        file))))

(defun paragtd-export--quietly ()
  "Export, never letting a failure get in the way of startup."
  (condition-case err
      (paragtd-export)
    (error (message "paragtd: could not write %s: %s" paragtd-export-file
                    (error-message-string err)))))

(defun paragtd-setup-export ()
  "Write the description once startup is done.
Not in batch Emacs (tests, `bin/paragtd-export'): a batch run has none
of the site's settings, and would describe the defaults instead."
  (unless noninteractive
    (if after-init-time
        (paragtd-export--quietly)
      (add-hook 'emacs-startup-hook #'paragtd-export--quietly))))

(provide 'paragtd-export)

;;; paragtd-export.el ends here
