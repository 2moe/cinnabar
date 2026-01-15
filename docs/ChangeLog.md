# ChangeLog

## v0.0.4 (2026-01-15)

> TL;DR: Refactor Path logic, introduce GemPath, update CI loading, and adjust RuboCop rules

- Introduced `Cinnabar::GemPath` and replaced legacy `Cinnabar::Path` gem‑loading logic.
- Updated `ci.rb` to use new `gem_paths_proc` and JSON cache file.
- Removed large monolithic gem‑path utilities from `path.rb`.
- Added new `utils` require and reorganized require order.
- Adjusted `.rubocop.yml`: disabled `Style/RescueModifier`.

## v0.0.2 (2026-01-05)

- fix ruby v4.0.0 compatibility
