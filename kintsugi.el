;;; kintsugi.el --- Major mode for the Kintsugi Programming Language -*- lexical-binding: t; -*-

;; Author: Ray Perry
;; Date: <2026-03-26>

;;; Code:

(defgroup kintsugi nil
  "Major mode for the Kintsugi programming language."
  :group 'languages
  :prefix "kintsugi-")

(defcustom kintsugi-indent-offset 2
  "Number of spaces for each indentation level in Kintsugi."
  :type 'integer
  :group 'kintsugi)

(defvar kintsugi-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\; "<" st)
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?- "_" st)
    (modify-syntax-entry ?? "_" st)
    (modify-syntax-entry ?! "_" st)
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?/ "_" st)
    (modify-syntax-entry ?~ "_" st)
    (modify-syntax-entry ?{ "|" st)
    (modify-syntax-entry ?} "|" st)
    st)
  "Syntax table for `kintsugi-mode'.")

;; Type names — single source; predicates (name?) generated from these.
(defconst kintsugi--type-names
  '("integer" "float" "money" "string" "logic" "none"
    "pair" "tuple" "date" "time" "file"
    "url" "email" "word" "set-word" "get-word" "lit-word" "meta-word"
    "block" "paren" "map" "set" "context" "object" "function"
    "native" "op" "type" "frozen"
    ;; Union types
    "any-type" "number" "any-word" "any-block" "scalar")
  "Type names without ! suffix.")

(defconst kintsugi-font-lock-keywords
  (let ((control '("if" "either" "unless" "loop" "break" "return"
                    "function" "does" "try" "match" "attempt" "scope"
                    "not" "and" "or" "all?" "any?"
                    ;; Loop dialect keywords
                    "for" "in" "from" "to" "by" "when" "do" "it"
                    ;; Attempt dialect keywords
                    "source" "then" "fallback" "retries" "catch"
                    ;; Match dialect keywords
                    "default"
                    ;; Object dialect keywords
                    "fields" "required" "optional" "include"
                    ;; @game dialect keywords
                    "entity" "collide" "collide/using" "on-update"
                    "constants" "state" "tags"
                    ;; Bindings dialect
                    "bindings" "import"
                    ;; Assert
                    "assert"))
        (builtins (append
                    '("print" "probe" "reduce" "apply"
                      "select" "first" "second" "last" "pick" "find" "reverse"
                      "append" "insert" "remove" "copy" "sort"
                      "has?" "is?"
                      "length" "empty?" "type"
                      "odd?" "even?" "number?" "function?"
                      "min" "max" "abs" "negate" "round" "sqrt"
                      "sin" "cos" "tan" "asin" "acos" "atan2"
                      "pow" "exp" "log" "log10"
                      "floor" "ceil" "to-degrees" "to-radians"
                      "random" "pi"
                      "join" "rejoin" "replace" "split" "trim"
                      "uppercase" "lowercase"
                      "starts-with?" "ends-with?" "subset"
                      "byte" "char"
                      "context" "object" "freeze" "frozen?" "words" "set" "merge"
                      "make" "to" "using"
                      "union" "intersect"
                      "load" "import" "save" "exports"
                      "read" "write" "dir?" "file?" "exit"
                      "error" "now" "time" "date" "system"
                      "pad" "capture"
                      ;; Preprocess / compile-time
                      "emit" "raw")
                    ;; Generated: integer? float? string? etc.
                    (mapcar (lambda (name) (concat name "?"))
                            kintsugi--type-names))))
    `(
      ;; Meta-words (@type, @const, @template, @compose, @preprocess, etc.)
      ;; Not preceded by alnum (that's email)
      ("\\(?:^\\|[^[:alnum:]._-]\\)\\(@[[:alpha:]][[:alnum:]_?!~/-]*\\)"
       1 font-lock-preprocessor-face)
      ;; Chain operator ->
      ("->" . font-lock-keyword-face)
      ;; Field declaration keywords (contain /)
      ("\\bfield/\\(?:required\\|optional\\)\\b" . font-lock-keyword-face)
      ;; URL literals (before email and file to avoid partial matches)
      ("[[:alpha:]][[:alnum:]+-]*://[^] \t\n[()]*" . font-lock-string-face)
      ;; Email literals (require alnum before @ to avoid matching @meta-words)
      ("[[:alnum:]][[:alnum:]._-]*@[[:alnum:]._-]+" . font-lock-string-face)
      ;; File literals (including quoted: %"path with spaces")
      ("%\"[^\"]*\"" . font-lock-string-face)
      ("%[^] \t\n[(){}]+" . font-lock-string-face)
      ;; Money literals ($19.99, -$0.50)
      ("-?\\$[0-9]+\\(?:\\.[0-9]+\\)?" . font-lock-constant-face)
      ;; Pair literals (NxN, with optional decimals and negative second component)
      ("-?[0-9]+\\(?:\\.[0-9]+\\)?x-?[0-9]+\\(?:\\.[0-9]+\\)?" . font-lock-constant-face)
      ;; Logic and none (true/false are keywords, on/off/yes/no are words bound to logic)
      (,(regexp-opt '("true" "false" "on" "off" "yes" "no" "none") 'symbols)
       . font-lock-constant-face)
      ;; Set-words (word:) — before type names so word!: gets set-word face
      ("\\_<[[:alpha:]][[:alnum:]_?!~-]*:" . font-lock-variable-name-face)
      ;; Type names (word!) — `/` permitted inside so enum singleton
      ;; types like `direction/north!` highlight as a single type.
      ("\\_<[[:alpha:]][[:alnum:]_/-]*!" . font-lock-type-face)
      ;; Lit-words ('word)
      ("'[[:alpha:]][[:alnum:]_?!~-]*" . font-lock-constant-face)
      ;; Get-words (:word)
      ("\\(?:^\\|[^[:alnum:]_?!~-]\\)\\(:[[:alpha:]][[:alnum:]_?!~-]*\\)"
       1 font-lock-builtin-face)
      ;; Control flow keywords
      (,(regexp-opt control 'symbols) . font-lock-keyword-face)
      ;; Builtins
      (,(regexp-opt builtins 'symbols) . font-lock-builtin-face)
      ;; Header keyword
      ("^Kintsugi\\b" . font-lock-keyword-face)))
  "Font-lock keywords for `kintsugi-mode'.")

(defun kintsugi-indent-line ()
  "Indent current line as Kintsugi code."
  (let* ((ppss (save-excursion (beginning-of-line) (syntax-ppss)))
         (depth (car ppss)))
    (unless (or (nth 3 ppss) (nth 4 ppss))
      (let* ((closing (save-excursion
                        (back-to-indentation)
                        (looking-at "[])]")))
             (target (* kintsugi-indent-offset
                        (max 0 (if closing (1- depth) depth)))))
        (if (<= (current-column) (current-indentation))
            (indent-line-to target)
          (save-excursion (indent-line-to target)))))))

;;;###autoload
(define-derived-mode kintsugi-mode prog-mode "Kintsugi"
  "Major mode for the Kintsugi Programming Language."
  :syntax-table kintsugi-mode-syntax-table
  (setq-local comment-start "; ")
  (setq-local comment-end "")
  (setq-local font-lock-defaults '(kintsugi-font-lock-keywords))
  (setq-local indent-line-function #'kintsugi-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ktg\\'" . kintsugi-mode))

(provide 'kintsugi)
;;; kintsugi.el ends here
