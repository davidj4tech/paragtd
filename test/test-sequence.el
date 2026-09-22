;;; test-sequence.el --- end-to-end checks for sequenced projects -*- lexical-binding: t; -*-
;; Run with: emacs --batch -l test/test-sequence.el
;; Set PARAGTD_EDNA_DIR to a package-user-dir containing org-edna to also
;; exercise date propagation; without it, only blocking is checked.

(add-to-list 'load-path (expand-file-name "../lisp" (file-name-directory load-file-name)))

(let ((edna-dir (getenv "PARAGTD_EDNA_DIR")))
  (when (and edna-dir (file-directory-p edna-dir))
    (setq package-user-dir edna-dir)
    (require 'package)
    (package-initialize)))

(require 'org)
(require 'paragtd)
(paragtd-setup)

(defun paragtd-test--fixture ()
  (let ((file (make-temp-file "paragtd-seq" nil ".org")))
    (with-temp-file file
      (insert "* TODO Ship the thing\n"
              "** TODO Draft it\n"
              "** TODO Review it\n"
              "** TODO Publish it\n"))
    file))

(defun paragtd-test--check (name form)
  (if form
      (princ (format "  ok   %s\n" name))
    (princ (format "  FAIL %s\n" name))
    (error "Test failed: %s" name)))

(princ "paragtd sequence tests\n")

;; Keywords the capture templates and triggers rely on must exist.
(let ((all (apply #'append (mapcar #'cdr org-todo-keywords))))
  (paragtd-test--check "NEXT is a real TODO keyword" (member "NEXT(n)" all))
  (paragtd-test--check "WAITING is a real TODO keyword" (member "WAITING(w@/!)" all)))

(paragtd-test--check "dependencies are enforced" org-enforce-todo-dependencies)
(paragtd-test--check "blocked tasks are dimmed" org-agenda-dim-blocked-tasks)

;; Stamping a subtree.
(let ((file (paragtd-test--fixture)))
  (with-current-buffer (find-file-noselect file)
    (org-mode)
    (goto-char (point-min))
    (paragtd-sequence-subtree)
    (goto-char (point-min))
    (paragtd-test--check "project is ORDERED"
                         (equal "t" (org-entry-get nil "ORDERED")))
    (search-forward "Draft it")
    (paragtd-test--check "first step becomes NEXT"
                         (equal "NEXT" (org-get-todo-state)))
    (paragtd-test--check "first step triggers the next"
                         (org-entry-get nil "TRIGGER"))
    (search-forward "Publish it")
    (paragtd-test--check "last step triggers nothing"
                         (null (org-entry-get nil "TRIGGER")))

    ;; Blocking: the third step cannot close while the second is open.
    (goto-char (point-min))
    (search-forward "Publish it")
    (paragtd-test--check "a later step is blocked"
                         (let ((org-blocker-hook org-blocker-hook))
                           (condition-case nil
                               (progn (org-todo "DONE")
                                      (not (equal "DONE" (org-get-todo-state))))
                             (error t))))

    ;; Date propagation, only when org-edna is present.
    (if (not (paragtd-sequence-edna-available-p))
        (princ "  skip org-edna date propagation (not installed)\n")
      (goto-char (point-min))
      (search-forward "Draft it")
      (org-todo "DONE")
      (goto-char (point-min))
      (search-forward "Review it")
      (paragtd-test--check "finishing a step makes the next NEXT"
                           (equal "NEXT" (org-get-todo-state)))
      (let ((sched (org-entry-get nil "SCHEDULED")))
        (paragtd-test--check "finishing a step dates the next" sched)
        (paragtd-test--check "the date is today (lag 0)"
                             (= 0 (org-time-stamp-to-now sched))))))
  (delete-file file))

(princ "paragtd sequence tests OK\n")
