;;; test-zettel.el --- reviewing draft zettels -*- lexical-binding: t; -*-
;; Run with: emacs --batch -l test/test-zettel.el

(add-to-list 'load-path (expand-file-name "../lisp" (file-name-directory load-file-name)))
(require 'org)
(require 'paragtd)

(defvar org-roam-capture-templates)  ; org-roam is not loaded in batch
(defvar paragtd-test-failures 0)
(defun paragtd-test-check (ok what)
  (princ (format "%s %s\n" (if ok "PASS" "FAIL") what))
  (unless ok (setq paragtd-test-failures (1+ paragtd-test-failures))))

(let* ((dir (make-temp-file "paragtd-zettel" t))
       (paragtd-roam-directory dir)
       (notes (expand-file-name "notes" dir))
       (a (expand-file-name "20260927T100000==aaaa1111z1--pauses-undo__zk_inbox.org" notes))
       (b (expand-file-name "20260928T100000--my-idea__inbox.org" notes))
       (c (expand-file-name "20260101T000000--old-kept__zk.org" notes)))
  (make-directory notes)
  (with-temp-file a
    (insert ":PROPERTIES:\n:ID:          zk:aaaa1111:1\n:ZK_STATUS:   draft\n:END:\n"
            "#+title: Pauses must be undone\n#+filetags: :zk:inbox:\n\nBody.\n"))
  (with-temp-file b
    (insert "#+title: My idea\n#+filetags: :zettel:inbox:\n\nMine.\n"))
  (with-temp-file c
    (insert "#+title: Old kept\n#+filetags: :zk:\n\nKept.\n"))
  (let ((drafts (paragtd-zettel-drafts)))
    (paragtd-test-check (equal (mapcar #'car drafts) '("Pauses must be undone" "My idea"))
                        "drafts are the inbox-tagged notes, oldest first"))
  (paragtd-zettel-review)
  (paragtd-test-check (equal buffer-file-name a) "review visits the oldest draft")
  (paragtd-zettel-promote)
  (let ((kept (expand-file-name "20260927T100000==aaaa1111z1--pauses-undo__zk.org" notes)))
    (paragtd-test-check (and (file-exists-p kept) (not (file-exists-p a))) "promote drops _inbox from the name")
    (paragtd-test-check (equal buffer-file-name kept) "and the buffer follows")
    (let ((text (with-temp-buffer (insert-file-contents kept) (buffer-string))))
      (paragtd-test-check (string-match-p "^#\\+filetags: :zk:$" text) "promote drops the inbox tag")
      (paragtd-test-check (string-match-p "^:ZK_STATUS: +permanent$" text) "and marks it permanent")
      (paragtd-test-check (string-match-p "^:ID: +zk:aaaa1111:1$" text) "the id is kept")))
  (kill-buffer)
  (find-file b)
  (paragtd-zettel-promote)
  (paragtd-test-check (file-exists-p (expand-file-name "20260928T100000--my-idea.org" notes))
                      "a hand note without keywords left loses the __ too")
  (kill-buffer)
  (paragtd-test-check (null (paragtd-zettel-drafts)) "inbox empty after review")
  (let ((org-roam-capture-templates '(("d" "default" plain "%?"))))
    (paragtd-zettel--add-capture)
    (paragtd-zettel--add-capture)
    (paragtd-test-check (equal (mapcar #'car org-roam-capture-templates) '("d" "z"))
                        "capture template added once, after the user's own")))

(kill-emacs (if (zerop paragtd-test-failures) 0 1))
