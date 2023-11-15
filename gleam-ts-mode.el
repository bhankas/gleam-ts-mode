;;; gleam-ts-mode.el --- Major mode for Gleam, powered by tree-sitter -*- lexical-binding: t -*-

;; Maintainer: Payas Relekar <payas@relekar.org>
;; Homepage: https://github.com/bhankas/gleam-ts-mode
;; Version: 0.0.1
;; Keywords: gleam languages
;; Package-Requires: ((emacs "29.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; Provides syntax highlighting, indentation, and code navigation
;; features for the Gleam programming language, powered by the new
;; built-in tree-sitter support in Emacs 29.1.

;;; Code:

(require 'treesit)
(require 'c-ts-common)
(require 'rx)

(unless (treesit-available-p)
  (error "`gleam-ts-mode` requires Emacs to be built with tree-sitter support"))

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")
(declare-function treesit-node-type "treesit.c")

;;; Customization
(defgroup gleam-ts nil
  "Major mode for Gleam."
  :prefix "gleam-ts-"
  :group 'languages)

(defcustom gleam-ts-mode-hook nil
  "Hook that runs when `gleam-mode' starts."
  :type 'hook
  :group 'gleam-ts)

(defcustom gleam-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `gleam-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'gleam-ts)

(defconst gleam-ts-mode--brackets
  '("(" ")" "[" "]" "{" "}" "<<" ">>")
  "Gleam brackets for tree-sitter font-locking.")

(defconst gleam-ts-mode--operators
  '("+" "-" "*" "/" "<" ">" "<=" ">=" "%" "+." "-." "*." "/." "<." ">." "<=." ">=." ":" "," "#" "!" "=" "==" "!=" "|" "||" "&&" "<<" ">>" "|>" "." "->" "<-" ".." "EOF" "//" "///" "@" "////" "<>")
  "Gleam operators for tree-sitter font-locking.")

(defun gleam-ts-mode--string-highlight-helper ()
  "Return a query for strings."
  (condition-case nil
      (progn (treesit-query-capture 'gleam '((text_block) @font-lock-string-face))
             `((string_literal) @font-lock-string-face
               (text_block) @font-lock-string-face))
    (error
     `((string_literal) @font-lock-string-face))))

;; Settings
(defvar gleam-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'gleam
   :feature 'bracket
   `([ @gleam-ts-mode--brackets ] @font-lock-bracket-face)

   :language 'gleam
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'gleam
   :feature 'keyword
   `([ "EMPTYLINE" "as" "assert" "case" "const" "fn" "if" "import" "let" "opaque" "pub" "todo" "use" "type" "panic" ] @font-lock-keyword-face)

   :language 'gleam
   :feature 'string
   :override t
   (gleam-ts-mode--string-highlight-helper)

   :language 'gleam
   :feature 'operator
   `([ ,@gleam-ts-mode--operators ] @font-lock-operator-face)

   :language 'gleam
   :feature 'number
   `([(integer) (float)] @font-lock-number-face)

   :language 'gleam
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for `gleam-ts-mode'.")

;; Indentation
(defvar gleam-ts-mode-indent-rules
  `((gleam
     ((parent-is "source_code") column-0 0)
     ((node-is "]") parent-bol 0)
     ((node-is ")") parent-bol 0)
     ((node-is "}") parent-bol 0)))
  "Tree-sitter indent rules for `gleam-ts-mode'.")

;; Keymap
(defvar gleam-ts-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for `gleam-ts-mode'.")

;;;###autoload
(define-derived-mode gleam-ts-mode prog-mode "Gleam"
  "Major mode for editing Gleam source code, powered by tree-sitter."
  ;; :syntax-table gleam-ts-mode--syntax-table

  (when (treesit-ready-p 'gleam)
    (treesit-parser-create 'gleam)

    ;; Font locking
    (setq-local treesit-font-lock-settings gleam-ts-mode--font-lock-settings)

    (setq-local treesit-font-lock-feature-list
                '((comment builtin)
                  (keyword string path)
                  (number constant attribute)
                  (bracket error operator)))

    ;; Comments
    (setq-local comment-start "//")

    ;; Indentation
    (setq-local treesit-simple-indent-rules gleam-ts-mode-indent-rules)

    ;; Imenu.
    (setq-local treesit-simple-imenu-settings
                `((nil "\\`binding\\'" nil nil)))

    ;; Navigation.
    (setq-local treesit-defun-type-regexp (rx (or "binding")))

    (treesit-major-mode-setup)))

(provide 'gleam-ts-mode)
;;; gleam-ts-mode.el ends here
;; End:
