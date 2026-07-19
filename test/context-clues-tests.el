;;; context-clues-tests.el --- Tests for context-clues -*- lexical-binding: t; -*-

;;; Commentary:

;; Run from the repository root with:
;;
;;   emacs -Q --batch -l test/context-clues-tests.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)

(add-to-list 'load-path
             (expand-file-name
              ".." (file-name-directory (or load-file-name buffer-file-name))))
(require 'context-clues)

(defmacro context-clues-tests--with-file-buffer (extension content &rest body)
  "Run BODY in a buffer visiting a temp file with EXTENSION and CONTENT.
The absolute file name is bound to `file' around BODY.  The buffer and
file are cleaned up afterwards."
  (declare (indent 2))
  `(let* ((file (make-temp-file "context-clues-test" nil ,extension))
          (buffer (find-file-noselect file)))
     (unwind-protect
         (with-current-buffer buffer
           (insert ,content)
           ,@body)
       (when (buffer-live-p buffer)
         (with-current-buffer buffer
           (set-buffer-modified-p nil))
         (kill-buffer buffer))
       (delete-file file))))

;;; File and path clues

(ert-deftest context-clues-test-file-name ()
  (context-clues-tests--with-file-buffer ".txt" "hello\n"
    (should (equal (context-clues--file-name)
                   (file-name-nondirectory file)))))

(ert-deftest context-clues-test-file-name-non-file-buffer ()
  (with-temp-buffer
    (should-not (context-clues--file-name))))

(ert-deftest context-clues-test-file-with-line ()
  (context-clues-tests--with-file-buffer ".txt" "one\ntwo\nthree\n"
    (goto-char (point-min))
    (forward-line 1)
    (should (equal (context-clues--file-with-line)
                   (format "%s:2" (file-name-nondirectory file))))))

(ert-deftest context-clues-test-relative-path-outside-project ()
  ;; Outside a project the path falls back to `default-directory',
  ;; leaving just the base name for a file in that directory.
  (context-clues-tests--with-file-buffer ".txt" ""
    (should (equal (context-clues--relative-path-value)
                   (file-name-nondirectory file)))))

;;; Copy commands

(ert-deftest context-clues-test-copy-pushes-to-kill-ring ()
  (context-clues-tests--with-file-buffer ".txt" "hello\n"
    (let ((kill-ring nil)
          (kill-ring-yank-pointer nil))
      (context-clues-copy-file-name)
      (should (equal (car kill-ring) (file-name-nondirectory file))))))

(ert-deftest context-clues-test-copy-errors-in-non-file-buffer ()
  (with-temp-buffer
    (should-error (context-clues-copy-file-name) :type 'user-error)))

;;; Previews

(ert-deftest context-clues-test-preview-short-value-unchanged ()
  (should (equal (substring-no-properties (context-clues--preview "short"))
                 "short")))

(ert-deftest context-clues-test-preview-long-value-keeps-tail ()
  (let ((context-clues-preview-max-width 10))
    (let ((preview (substring-no-properties
                    (context-clues--preview "abcdefghijklmnopqrst"))))
      (should (= (length preview) 10))
      (should (string-prefix-p "…" preview))
      (should (string-suffix-p "lmnopqrst" preview)))))

(ert-deftest context-clues-test-preview-nil-value ()
  (should-not (context-clues--preview nil)))

(ert-deftest context-clues-test-describe-pads-label ()
  (let ((description (context-clues--describe "Label" "value")))
    (should (string-prefix-p "Label" description))
    (should (string-suffix-p "value" description))
    (should (= (length (substring-no-properties description))
               (+ context-clues--label-width (length "value"))))))

(ert-deftest context-clues-test-describe-nil-value-bare-label ()
  (should (equal (context-clues--describe "Label" nil) "Label")))

;;; Breadcrumb

(ert-deftest context-clues-test-imenu-join-parts ()
  (let ((context-clues-breadcrumb-separator " > "))
    (should (equal (context-clues--imenu-join-parts '("a" "b")) "a > b"))
    ;; Markdown's "." self-heading entries are dropped.
    (should (equal (context-clues--imenu-join-parts '("a" "." "b")) "a > b"))
    (should-not (context-clues--imenu-join-parts '(".")))
    (should-not (context-clues--imenu-join-parts nil))))

(ert-deftest context-clues-test-breadcrumb-non-file-buffer ()
  (with-temp-buffer
    (should-not (context-clues--breadcrumb))))

(ert-deftest context-clues-test-breadcrumb-org-outline-path ()
  (context-clues-tests--with-file-buffer ".org" "* Top\n** Sub\nbody\n"
    (org-mode)
    (goto-char (point-max))
    (should (equal (context-clues--breadcrumb)
                   (format "%s > Top > Sub" (file-name-nondirectory file))))))

(ert-deftest context-clues-test-breadcrumb-org-before-first-heading ()
  (context-clues-tests--with-file-buffer ".org" "preamble\n* Top\n"
    (org-mode)
    (goto-char (point-min))
    (should (equal (context-clues--breadcrumb)
                   (file-name-nondirectory file)))))

(ert-deftest context-clues-test-breadcrumb-elisp-defun ()
  (context-clues-tests--with-file-buffer ".el" "(defun test-fn ()\n  nil)\n"
    (emacs-lisp-mode)
    (goto-char (point-min))
    (search-forward "nil")
    (should (equal (context-clues--breadcrumb)
                   (format "%s > test-fn" (file-name-nondirectory file))))))

(ert-deftest context-clues-test-breadcrumb-nested-imenu-index ()
  ;; A synthetic nested index, as built by e.g. markdown-mode: sections
  ;; nest, and a "." leaf marks a section's own heading.
  (context-clues-tests--with-file-buffer ".txt" "one\ntwo\nthree\n"
    (setq-local imenu--index-alist
                `(("Top" ("." . ,(copy-marker 1))
                   ("Sub" . ,(copy-marker 5)))))
    (goto-char (point-max))
    (should (equal (context-clues--breadcrumb)
                   (format "%s > Top > Sub" (file-name-nondirectory file))))))

(ert-deftest context-clues-test-breadcrumb-custom-separator ()
  (context-clues-tests--with-file-buffer ".org" "* Top\n** Sub\nbody\n"
    (org-mode)
    (goto-char (point-max))
    (let ((context-clues-breadcrumb-separator " » "))
      (should (equal (context-clues--breadcrumb)
                     (format "%s » Top » Sub"
                             (file-name-nondirectory file)))))))

(provide 'context-clues-tests)
;;; context-clues-tests.el ends here
