;;; context-clues-tests.el --- Tests for context-clues -*- lexical-binding: t; -*-

;;; Commentary:

;; Run from the repository root with:
;;
;;   emacs -Q --batch -l test/context-clues-tests.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'cl-lib)
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

(defmacro context-clues-tests--with-git-repo (&rest body)
  "Run BODY with `default-directory' set to a fresh git repository."
  (declare (indent 0))
  `(let ((default-directory
          (file-name-as-directory
           (make-temp-file "context-clues-test-repo" t))))
     (unwind-protect
         (progn
           (shell-command-to-string "git init -q -b main .")
           ,@body)
       (delete-directory default-directory t))))

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

(ert-deftest context-clues-test-full-path ()
  (context-clues-tests--with-file-buffer ".txt" ""
    (should (equal (context-clues--full-path) file))))

(ert-deftest context-clues-test-full-path-non-file-buffer ()
  (with-temp-buffer
    (should-not (context-clues--full-path))))

(ert-deftest context-clues-test-directory ()
  (context-clues-tests--with-file-buffer ".txt" ""
    (should (equal (context-clues--directory)
                   (file-name-directory file)))))

(ert-deftest context-clues-test-directory-non-file-buffer ()
  ;; Non-file buffers fall back to `default-directory'.
  (with-temp-buffer
    (should (equal (context-clues--directory) default-directory))))

(ert-deftest context-clues-test-relative-path-outside-project ()
  ;; Outside a project the path falls back to `default-directory',
  ;; leaving just the base name for a file in that directory.
  (context-clues-tests--with-file-buffer ".txt" ""
    (should (equal (context-clues--relative-path-value)
                   (file-name-nondirectory file)))))

(ert-deftest context-clues-test-relative-path-inside-project ()
  (context-clues-tests--with-git-repo
    (make-directory "sub")
    (write-region "" nil "sub/file.txt" nil 'quiet)
    (let ((buffer (find-file-noselect "sub/file.txt")))
      (unwind-protect
          (with-current-buffer buffer
            (should (equal (context-clues--relative-path-value)
                           "sub/file.txt")))
        (kill-buffer buffer)))))

(ert-deftest context-clues-test-relative-path-with-line ()
  (context-clues-tests--with-file-buffer ".txt" "one\ntwo\n"
    (goto-char (point-min))
    (forward-line 1)
    (should (equal (context-clues--relative-path-with-line)
                   (format "%s:2" (file-name-nondirectory file))))))

(ert-deftest context-clues-test-line-number ()
  (context-clues-tests--with-file-buffer ".txt" "one\ntwo\nthree\n"
    (goto-char (point-min))
    (forward-line 2)
    (should (equal (context-clues--line-number) "3"))))

(ert-deftest context-clues-test-buffer-name ()
  (with-temp-buffer
    (should (equal (context-clues--buffer-name) (buffer-name)))))

;;; Project clues

(ert-deftest context-clues-test-project-name ()
  (context-clues-tests--with-git-repo
    (should (equal (context-clues--project-name)
                   (file-name-nondirectory
                    (directory-file-name default-directory))))))

(ert-deftest context-clues-test-project-name-outside-project ()
  (let ((default-directory
         (file-name-as-directory
          (make-temp-file "context-clues-test-noproject" t))))
    (unwind-protect
        (should-not (context-clues--project-name))
      (delete-directory default-directory t))))

;;; Git clues

(ert-deftest context-clues-test-in-git-repo-p ()
  (context-clues-tests--with-git-repo
    (should (context-clues--in-git-repo-p))))

(ert-deftest context-clues-test-not-in-git-repo ()
  (let ((default-directory
         (file-name-as-directory
          (make-temp-file "context-clues-test-norepo" t))))
    (unwind-protect
        (should-not (context-clues--in-git-repo-p))
      (delete-directory default-directory t))))

(ert-deftest context-clues-test-git-branch ()
  (context-clues-tests--with-git-repo
    (should (equal (context-clues--git-branch) "main"))))

(ert-deftest context-clues-test-git-branch-detached-head ()
  (context-clues-tests--with-git-repo
    (shell-command-to-string
     (concat "git -c user.email=t@t.t -c user.name=t"
             " commit -q --allow-empty -m init"
             " && git checkout -q --detach"))
    (should-not (context-clues--git-branch))))

(ert-deftest context-clues-test-copy-git-branch-outside-repo ()
  (let ((default-directory
         (file-name-as-directory
          (make-temp-file "context-clues-test-norepo" t))))
    (unwind-protect
        (should-error (context-clues-copy-git-branch) :type 'user-error)
      (delete-directory default-directory t))))

;;; Copy commands

(ert-deftest context-clues-test-copy-pushes-to-kill-ring ()
  (context-clues-tests--with-file-buffer ".txt" "hello\n"
    (let ((kill-ring nil)
          (kill-ring-yank-pointer nil))
      (context-clues-copy-file-name)
      (should (equal (car kill-ring) (file-name-nondirectory file))))))

(ert-deftest context-clues-test-copy-errors-in-non-file-buffer ()
  (with-temp-buffer
    (should-error (context-clues-copy-file-name) :type 'user-error)
    (should-error (context-clues-copy-full-path) :type 'user-error)
    (should-error (context-clues-copy-relative-path) :type 'user-error)
    (should-error (context-clues-copy-file-with-line) :type 'user-error)
    (should-error (context-clues-copy-breadcrumb) :type 'user-error)))

(ert-deftest context-clues-test-copy-message-format ()
  ;; {text} and {description} are substituted, in any order.
  (let ((context-clues-message-format "{description}: {text}")
        (kill-ring nil)
        (kill-ring-yank-pointer nil)
        captured)
    (cl-letf (((symbol-function 'message)
               (lambda (fmt &rest args)
                 (setq captured (apply #'format fmt args)))))
      (context-clues--copy-to-kill-ring "TEXT" "DESC"))
    (should (equal captured "DESC: TEXT"))
    (should (equal (car kill-ring) "TEXT"))))

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

(ert-deftest context-clues-test-describe-wrappers ()
  ;; A wrapper pairs its label with the clue's value: padded label plus
  ;; preview when the clue applies, bare label when it does not.
  (context-clues-tests--with-file-buffer ".txt" ""
    (let ((description (context-clues--describe-file-name)))
      (should (string-prefix-p "File name" description))
      (should (string-suffix-p (file-name-nondirectory file) description))))
  (with-temp-buffer
    (should (equal (context-clues--describe-file-name) "File name"))))

;;; Function name

(ert-deftest context-clues-test-function-name ()
  (context-clues-tests--with-file-buffer ".el" "(defun test-fn ()\n  nil)\n"
    (emacs-lisp-mode)
    (goto-char (point-min))
    (search-forward "nil")
    (should (equal (context-clues--function-name) "test-fn"))))

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

(ert-deftest context-clues-test-breadcrumb-treesit-nested-defuns ()
  ;; Skips unless the python grammar is installed in a default treesit
  ;; location (`emacs -Q' does not see grammars kept elsewhere).
  (skip-unless (and (require 'treesit nil t)
                    (fboundp 'treesit-ready-p)
                    (treesit-ready-p 'python t)))
  (context-clues-tests--with-file-buffer
      ".py" "class Foo:\n    def bar(self):\n        pass\n"
    (python-ts-mode)
    (goto-char (point-min))
    (search-forward "pas")
    (should (equal (context-clues--breadcrumb)
                   (format "%s > Foo > bar"
                           (file-name-nondirectory file))))))

;;; Menu

(ert-deftest context-clues-test-menu-defined ()
  (should (fboundp 'context-clues))
  (should (get 'context-clues 'transient--prefix)))

(provide 'context-clues-tests)
;;; context-clues-tests.el ends here
