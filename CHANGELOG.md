# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Types of changes:

- `Added`: for new features.
- `Changed`: for changes in existing functionality.
- `Deprecated`: for soon-to-be removed features.
- `Removed`: for now removed features.
- `Fixed`: for any bug fixes.
- `Security`: in case of vulnerabilities.

## [0.3.0] - 2026-07-19

### Added

- Breadcrumb clue (`>`): copies the relative path followed by the context at
  point: the full heading path in Org and Markdown buffers, the nested function
  path in code (e.g., `src/models.py > MyClass > my_method`).  Tree-sitter
  buffers get the full defun nesting; other modes take the nested imenu path at
  point.
- `context-clues-breadcrumb-separator` to customize the separator between
  breadcrumb components (default `" > "`).

## [0.2.0] - 2026-07-15

### Added

- Live value previews in the menu: each clue shows what it would copy, with
  labels on the left and values aligned on the right (inspired by
  [file-info](https://github.com/Artawower/file-info.el)'s layout).
- `context-clues-preview-max-width` and `context-clues-preview-face` to
  customize the previews.
- Autoload cookie for the `context-clues` menu command.

### Changed

- A clue is now grayed out exactly when it has no value — this newly covers
  a detached git HEAD (no branch) and buffers where no function name can be
  determined, which previously errored when invoked.

### Fixed

- The relative-path clues no longer error in a file buffer outside any
  project; the path falls back to being relative to `default-directory`.

## [0.1.0] - 2025-12-01

Initial release: transient menu copying file name, paths (relative /
absolute / with line number), directory, project name, buffer name, git
branch, line number, and function name to the kill ring.
