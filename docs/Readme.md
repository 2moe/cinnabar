# Cinnabar

[![Gem Version](https://badge.fury.io/rb/cinnabar.svg?icon=si%3Arubygems)](https://rubygems.org/gems/cinnabar)

A handy toolkit tailored for CI workflows.

---

| Language/語言                   | ID         |
| ------------------------------- | ---------- |
| English                         | en-Latn-US |
| [简体中文](./Readme-zh.md)      | zh-Hans-CN |
| [繁體中文](./Readme-zh-Hant.md) | zh-Hant-TW |

---

## Preface

Q: Why is it named Cinnabar?

A:

1. Cinnabar was an ingredient used by ancient Daoist alchemists in their elixirs, much like this project serves as an "ingredient" within CI workflows.
2. Cinnabar is toxic. This project was developed for *Dirty and Quick* purposes and may produce unexpected side effects—in a sense, it is not entirely harmless.
3. Cinnabar, a mineral form of mercury sulfide (HgS), is a deep red-colored stone. And ruby is also a deep red stone. Naming a Ruby project "Cinnabar" is particularly fitting.

## API DOC

![ClassDiagram](../misc/assets/svg/ClassDiagram.svg)

- Github Pages: <https://2moe.github.io/cinnabar>

## Quick Start

Github Actions for cinnabar

```yaml
env:
  # Speeds up script startup by disabling RubyGems
  RUBYOPT: "--disable=gems"
  default_ci_shell: ruby cinnabar/ci.rb {0}
  # optional values: debug, info, warn, error, fatal
  RUBY_LOG: "debug"

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: ${{env.default_ci_shell}}
    steps:
      - uses: actions/checkout@v6

      - name: clone cinnabar
        uses: actions/checkout@v6
        with:
          repository: 2moe/cinnabar
          path: cinnabar
          ref: v0.0.0

      - name: (example) run cargo command
        run: |
          {
            cargo: (),
            build: (),
            profile: 'release',
            verbose: true,
            target: 'x86_64-unknown-linux-musl'
          }
            .to_argv
            .run
```

## Examples

### Command Runner

```yaml
- run: |
    {
      cargo: (),
      build: (),
      profile: 'release',
      verbose: true,
      target: 'x86_64-unknown-linux-musl'
    }
      .to_argv
      .run
```
