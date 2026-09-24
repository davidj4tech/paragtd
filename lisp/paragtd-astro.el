;;; paragtd-astro.el --- Astrological alert generation for PARA/GTD -*- lexical-binding: t; -*-

(require 'paragtd-paths)

(defcustom paragtd-astro-generator-command
  (expand-file-name "bin/paragtd-astro-generate" (file-name-directory (directory-file-name (file-name-directory load-file-name))))
  "Command that generates Org astrological alerts."
  :type 'file
  :group 'paragtd)

(defcustom paragtd-astro-timezone "Australia/Melbourne"
  "IANA timezone used when writing astrological Org timestamps."
  :type 'string
  :group 'paragtd)

(defun paragtd-astro-generate-year (year)
  "Generate astrological alerts for YEAR into `astro.org`.
The new and full moon routines go to `lunar.org`, which is in the agenda;
the rest is for the \"A\" view.  The generator expects Kerykeion to be
available to Python."
  (interactive (list (read-number "Astro year: " (string-to-number (format-time-string "%Y")))))
  (let ((file (paragtd-file "astro.org")))
    (make-directory (file-name-directory file) t)
    (unless (file-executable-p paragtd-astro-generator-command)
      (user-error "Astro generator is not executable: %s" paragtd-astro-generator-command))
    (with-current-buffer (get-buffer-create "*paragtd astro* ")
      (erase-buffer)
      (let ((status (call-process paragtd-astro-generator-command nil t t
                                  "--year" (number-to-string year)
                                  "--output" file
                                  "--lunar-output" (paragtd-file "lunar.org")
                                  "--timezone" paragtd-astro-timezone)))
        (unless (zerop status)
          (error "Astro generation failed; see %s" (buffer-name)))))
    (find-file file)))

(provide 'paragtd-astro)
