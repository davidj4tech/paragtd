;;; paragtd.el --- PARA/GTD workflow package -*- lexical-binding: t; -*-

;;; Commentary:
;; Portable workflow layer for Org-based PARA, GTD, routines, astro alerts,
;; and reviewing zettels in the org-roam notes folder.

;;; Code:

(require 'paragtd-paths)
(require 'paragtd-capture)
(require 'paragtd-sequence)
(require 'paragtd-routines)
(require 'paragtd-astro)
(require 'paragtd-export)
(require 'paragtd-zettel)

;;;###autoload
(defun paragtd-setup ()
  "Set up the PARA/GTD workflow package."
  (interactive)
  (paragtd-setup-paths)
  (paragtd-setup-capture)
  (paragtd-setup-sequence)
  (paragtd-setup-zettel)
  (paragtd-setup-export))

(provide 'paragtd)

;;; paragtd.el ends here
