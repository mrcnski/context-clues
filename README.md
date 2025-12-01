# context-clues

Easily copy context like the current file name and path, using a convenient transient menu interface!

## Features

- **File name** - Copy base file name (e.g., `file.el`)
- **Full path** - Copy absolute file path
- **Directory** - Copy directory path (or default directory for non-file buffers)
- **Buffer name** - Copy current buffer name
- **Git branch** - Copy current git branch name
- **Line number** - Copy current line number
- **Function name** - Copy current function name

## Requirements

- Emacs 28.1 or later

## Installation

### Manual Installation

1. Clone or download this repository:

```bash
git clone https://github.com/yourusername/context-clues.git ~/.emacs.d/packages/context-clues
```

2. Add to your Emacs configuration:

```elisp
(add-to-list 'load-path "~/.emacs.d/packages/context-clues")
(require 'context-clues)
```

### Using use-package

```elisp
(use-package context-clues
  :load-path "~/.emacs.d/packages/context-clues"
  :bind ("C-c c" . context-clues))
```

## Usage

Run `M-x context-clues` to open the transient menu, then press the corresponding key to copy:

- `f` - Copy file name
- `F` - Copy full path (absolute)
- `d` - Copy directory
- `b` - Copy buffer name
- `g` - Copy git branch
- `l` - Copy line number
- `n` - Copy function name

Press `q` or `C-g` to quit the menu without copying anything.

## Customization

### Message Format

Customize the message shown after copying:

```elisp
(setq context-clues-message-format "Copied: {text} ({description})")
```

Use `{text}` for the copied text and `{description}` for the description (e.g., "file name"). You can reorder them as needed:

```elisp
;; Show description first
(setq context-clues-message-format "{description}: {text}")
```

### Key Binding

Bind to a convenient key:

```elisp
(global-set-key (kbd "C-c c") 'context-clues)
```

## License

GPL-3.0-or-later
