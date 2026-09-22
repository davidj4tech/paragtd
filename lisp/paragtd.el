;;; paragtd.el --- PARA/GTD workflow package -*- lexical-binding: t; -*-

;;; Commentary:
;; Portable workflow layer for Org-based PARA, GTD, routines, and astro alerts.

;;; Code:

(require 'paragtd-paths)
(require 'paragtd-capture)
(require 'paragtd-sequence)
(require 'paragtd-routines)
(require 'paragtd-astro)

;;;###autoload
(defun paragtd-setup ()
  "Set up the PARA/GTD workflow package."
  (interactive)
  (paragtd-setup-paths)
  (paragtd-setup-capture)
  (paragtd-setup-sequence))

(provide 'paragtd)

;;; paragtd.el ends here
