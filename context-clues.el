;;; context-clues.el --- Easily copy context like the current file name and path -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Marcin Swieczkowski
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (transient "0.3.0"))
;; Keywords: convenience, tools
;; URL: https://github.com/mrcnski/context-clues

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; context-clues provides a convenient transient menu for copying various
;; file, buffer, and code context information to the kill ring.
;;
;; Features:
;; - Copy base file name
;; - Copy absolute file path
;; - Copy directory path
;; - Copy buffer name
;; - Copy current git branch
;; - Copy current line number
;; - Copy current function name
;;
;; Usage:
;;   M-x context-clues
;;
;; This will open a transient menu with all available copy options.
;; Options that are not applicable to the current buffer (e.g., file name
;; for non-file-visiting buffers) will be disabled.

;;; Code:

(require 'transient)
(require 'which-func)

(defgroup context-clues nil
  "Copy file, buffer, and context information."
  :group 'convenience
  :prefix "context-clues-")

(defcustom context-clues-message-format "Copied {description}: {text}"
  "Format string for the message shown after copying.
Use {text} for the copied text and {description} for the description.
Example: \"Copied: {text} ({description})\" or \"{description}: {text}\""
  :type 'string
  :group 'context-clues)

;;; Helper Functions

(defun context-clues--buffer-file-name-p ()
  "Return non-nil if current buffer is visiting a file."
  (buffer-file-name))

(defun context-clues--in-git-repo-p ()
  "Return non-nil if current buffer is in a git repository."
  (locate-dominating-file default-directory ".git"))

(defun context-clues--copy-to-kill-ring (text description)
  "Copy TEXT to kill ring and display TEXT and DESCRIPTION."
  (kill-new text)
  (let ((msg (string-replace "{text}" text
                             (string-replace "{description}" description
                                             context-clues-message-format))))
    (message "%s" msg)))

;;; Copy Functions

(defun context-clues-copy-file-name ()
  "Copy the base file name of the current buffer."
  (interactive)
  (if-let ((file-name (buffer-file-name)))
      (let ((base-name (file-name-nondirectory file-name)))
        (context-clues--copy-to-kill-ring base-name "file name"))
    (user-error "Buffer is not visiting a file")))

(defun context-clues-copy-full-path ()
  "Copy the absolute file path of the current buffer."
  (interactive)
  (if-let ((file-name (buffer-file-name)))
      (context-clues--copy-to-kill-ring file-name "full path")
    (user-error "Buffer is not visiting a file")))

(defun context-clues-copy-directory ()
  "Copy the directory path of the current buffer.
For file-visiting buffers, copies the file's directory.
For non-file-visiting buffers, copies the default directory."
  (interactive)
  (let ((directory (if-let ((file-name (buffer-file-name)))
                       (file-name-directory file-name)
                     default-directory)))
    (context-clues--copy-to-kill-ring directory "directory")))

(defun context-clues-copy-buffer-name ()
  "Copy the current buffer name."
  (interactive)
  (context-clues--copy-to-kill-ring (buffer-name) "buffer name"))

(defun context-clues-copy-git-branch ()
  "Copy the current git branch name."
  (interactive)
  (if (context-clues--in-git-repo-p)
      (let ((branch (string-trim
                     (shell-command-to-string "git symbolic-ref --short HEAD 2>/dev/null"))))
        (if (string-empty-p branch)
            (user-error "Could not determine git branch")
          (context-clues--copy-to-kill-ring branch "git branch")))
    (user-error "Buffer is not in a git repository")))

(defun context-clues-copy-line-number ()
  "Copy the current line number."
  (interactive)
  (let ((line-num (number-to-string (line-number-at-pos))))
    (context-clues--copy-to-kill-ring line-num "line number")))

(defun context-clues-copy-function-name ()
  "Copy the current function name."
  (interactive)
  (if-let ((func-name (which-function)))
      (context-clues--copy-to-kill-ring func-name "function name")
    (user-error "Could not determine current function")))

;;; Transient Menu

(transient-define-prefix context-clues ()
  "Copy file, buffer, and context information."
  ["File & Buffer"
   [("f" "File name" context-clues-copy-file-name
     :inapt-if-not context-clues--buffer-file-name-p)
    ("F" "Full path (absolute)" context-clues-copy-full-path
     :inapt-if-not context-clues--buffer-file-name-p)
    ("d" "Directory" context-clues-copy-directory)]
   [("b" "Buffer name" context-clues-copy-buffer-name)
    ("g" "Git branch" context-clues-copy-git-branch
     :inapt-if-not context-clues--in-git-repo-p)]]
  ["Code Context"
   [("l" "Line number" context-clues-copy-line-number)
    ("n" "Function name" context-clues-copy-function-name)]])

(provide 'context-clues)

;;; context-clues.el ends here
