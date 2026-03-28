# kintsugi-mode

An Emacs major mode for the [Kintsugi](https://github.com/RaycatWhoDat/kintsugi) programming language.

## Features

- Syntax highlighting for keywords, builtins, type names, set-words, get-words, lit-words, meta-words, and literals (URLs, emails, files, money, pairs, logic)
- Indentation support
- Comment handling (`;` line comments, `{` `}` multi-line strings)

## Installation

### Manual

Clone this repository and add it to your load path:

```elisp
(add-to-list 'load-path "/path/to/kintsugi-mode")
(require 'kintsugi)
```

### use-package

```elisp
(use-package kintsugi
  :load-path "/path/to/kintsugi-mode")
```

## Usage

Files with a `.ktg` extension are automatically opened in `kintsugi-mode`.

## Configuration

```elisp
;; Set indentation width (default: 2)
(setq kintsugi-indent-offset 4)
```

## License

MIT
