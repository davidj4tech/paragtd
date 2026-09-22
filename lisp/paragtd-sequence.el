;;; paragtd-sequence.el --- Sequenced (Gantt-style) projects -*- lexical-binding: t; -*-

;;; Commentary:
;; Dependencies between tasks, in two layers.
;;
;; Blocking is built into Org: `org-enforce-todo-dependencies' plus an
;; :ORDERED: t property means a child cannot be marked DONE before its
;; older siblings, and blocked entries are dimmed in the agenda.  That
;; needs no external package.
;;
;; Dating is org-edna, which is optional.  When it is installed, a
;; :TRIGGER: property on each step schedules the next one at the moment
;; the current one is finished, which is the Gantt notion of "successor
;; starts when its predecessor completes, plus lag".
;;
;; The lag form is "++Nd": org-edna treats a single "+" (and the Org
;; repeater ".+") as an increment of an existing timestamp and errors
;; out when the target has no date.  "++" is measured from now, so it
;; works on an undated step, which is the normal case here.

;;; Code:

(require 'paragtd-paths)

(defcustom paragtd-sequence-default-lag 0
  "Days between finishing one step and the next step's scheduled date.
Zero schedules the next step for the day the previous one is closed."
  :type 'integer
  :group 'paragtd)

(defcustom paragtd-sequence-next-keyword "NEXT"
  "TODO keyword given to a step when its predecessor is finished.
Must be a keyword in `org-todo-keywords'."
  :type 'string
  :group 'paragtd)

(defcustom paragtd-sequence-use-edna t
  "Whether to enable `org-edna-mode' when org-edna is installed.
paragtd never installs org-edna itself; an editor config that wants
date propagation should add the package.  Blocking works without it."
  :type 'boolean
  :group 'paragtd)

(defun paragtd-sequence-trigger (&optional lag)
  "Return the :TRIGGER: value scheduling the next sibling after LAG days."
  (format "next-sibling todo!(%s) scheduled!(\"++%dd\")"
          paragtd-sequence-next-keyword
          (or lag paragtd-sequence-default-lag)))

(defun paragtd-sequence-edna-available-p ()
  "Return non-nil when org-edna can be loaded."
  (or (featurep 'org-edna) (locate-library "org-edna")))

(defun paragtd-sequence--children ()
  "Return markers at the direct children of the heading at point.
Markers, not positions: inserting a property drawer into one child
moves every later child, and plain positions would go stale mid-loop."
  (let ((level (org-current-level))
        (end (save-excursion (org-end-of-subtree t t)))
        children)
    (save-excursion
      (while (and (outline-next-heading) (< (point) end))
        (when (= (org-current-level) (1+ level))
          (push (copy-marker (point)) children))))
    (nreverse children)))

(defun paragtd-sequence--release (markers)
  "Point MARKERS nowhere, so they stop tracking the buffer."
  (dolist (marker markers)
    (set-marker marker nil)))

;;;###autoload
(defun paragtd-sequence-subtree (&optional lag)
  "Turn the subtree at point into a sequenced project.

Sets :ORDERED: t on the project heading, so Org blocks any step
whose older siblings are unfinished, and puts a :TRIGGER: on every
step but the last, so finishing one schedules the next LAG days
later.  LAG defaults to `paragtd-sequence-default-lag'; a prefix
argument prompts for it.

The first step is promoted to `paragtd-sequence-next-keyword' so
the project has a live next action straight away."
  (interactive
   (list (when current-prefix-arg
           (read-number "Days between steps: " paragtd-sequence-default-lag))))
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an Org buffer"))
  (org-back-to-heading t)
  (let ((children (paragtd-sequence--children))
        (trigger (paragtd-sequence-trigger lag)))
    (unless children
      (user-error "This heading has no steps to sequence"))
    (org-entry-put nil "ORDERED" "t")
    (save-excursion
      ;; Last step triggers nothing: there is nothing after it.
      (dolist (marker (butlast children))
        (goto-char marker)
        (org-entry-put nil "TRIGGER" trigger))
      (goto-char (car children))
      (when (equal (org-get-todo-state) "TODO")
        (org-todo paragtd-sequence-next-keyword)))
    (unless (paragtd-sequence-edna-available-p)
      (message "Sequenced: steps block in order. Install org-edna for dates."))
    (prog1 (length children)
      (paragtd-sequence--release children))))

;;;###autoload
(defun paragtd-sequence-unsequence ()
  "Remove the sequencing properties from the subtree at point."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an Org buffer"))
  (org-back-to-heading t)
  (org-entry-delete nil "ORDERED")
  (let ((children (paragtd-sequence--children)))
    (save-excursion
      (dolist (marker children)
        (goto-char marker)
        (org-entry-delete nil "TRIGGER")))
    (paragtd-sequence--release children)))

(defun paragtd-sequence--enable-edna ()
  "Turn on `org-edna-mode' if org-edna can be found."
  (when (paragtd-sequence-edna-available-p)
    (require 'org-edna)
    (org-edna-mode 1)
    t))

(defun paragtd-setup-sequence ()
  "Install task-dependency behaviour."
  (setq org-enforce-todo-dependencies t
        org-agenda-dim-blocked-tasks t)
  (when paragtd-sequence-use-edna
    (if (paragtd-sequence-edna-available-p)
        (paragtd-sequence--enable-edna)
      ;; paragtd-setup may run before the editor config has installed
      ;; org-edna or added it to `load-path', so look again once startup
      ;; has finished rather than deciding it is missing now.
      (add-hook 'emacs-startup-hook #'paragtd-sequence--enable-edna)))
  (with-eval-after-load 'org
    (define-key org-mode-map (kbd "C-c s") #'paragtd-sequence-subtree)))

(provide 'paragtd-sequence)

;;; paragtd-sequence.el ends here
