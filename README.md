<div align="center">
  <img src="logo.svg" alt="Context Clues Logo" width="200"/>

# context-clues

Easily copy context like the current file name and path, using a convenient transient menu interface!

<img src="screenshot.png" alt="context-clues transient showing different possible clues" width="550">
</div>

## Features

Every entry in the menu shows a **live preview** of the value it would copy —
labels on the left, values on the right. Entries that don't apply to the
current buffer are grayed out.

- **File name** - Copy base file name (e.g., `file.el`)
- **Relative path** - Copy relative path from project root (e.g., `src/lib/file.el`)
- **Full path** - Copy absolute file path
- **Directory** - Copy directory path (or default directory for non-file buffers)
- **File with line** - Copy file name with line number (e.g., `file.el:123`)
- ... and more!

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
- etc.

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

### Previews

Long values are truncated at the front (keeping the tail — for paths, the
distinctive part). Customize the width and the face:

```elisp
(setq context-clues-preview-max-width 60) ; default 50
```

The previews use the `context-clues-preview-face` face (inherits `shadow` by
default); customize it with `M-x customize-face`.

### Key Binding

Bind to a convenient key:

```elisp
(global-set-key (kbd "C-c c") 'context-clues)
```

## Requirements

- Emacs 28.1 or later

## License

GPL-3.0-or-later
