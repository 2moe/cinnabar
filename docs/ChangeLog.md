# ChangeLog

## v0.0.4 (2026-01-15)

> TL;DR: Refactor Path logic, introduce GemPath & Utils, update CI loading, and adjust RuboCop rules

- Introduced `Cinnabar::GemPath` and replaced legacy `Cinnabar::Path` gem‑loading logic.
- Updated `ci.rb` to use `new_gem_path_proc` and JSON cache file.
- Updated gem_path cache format:
  - DSL:`"#{k1}#{2spaces}#{v1}"` => json: `{"#{k1}": [v1, v2]}`
- Removed large monolithic gem‑path utilities from `path.rb`.
- Added `Cinnabar::Utils`
- Adjusted `.rubocop.yml`: disabled `Style/RescueModifier`.
- Added **misc/firb**

## v0.0.2 (2026-01-05)

- fix ruby v4.0.0 compatibility
