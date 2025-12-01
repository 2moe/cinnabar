# Cinnabar

[![Gem Version](https://badge.fury.io/rb/cinnabar.svg?icon=si%3Arubygems)](https://rubygems.org/gems/cinnabar)

專為 CI 流程打造的工具集。

---

| Language/語言              | ID         |
| -------------------------- | ---------- |
| 繁體中文                   | zh-Hant-TW |
| [English](./Readme.md)     | en-Latn-US |
| [简体中文](./Readme-zh.md) | zh-Hans-CN |

---

## 前言

**問：為何取名為 Cinnabar（硃砂）？**

**答：**

1.  硃砂是中國古代道教煉丹師在煉丹時使用的一種原料，就像這個專案在 CI 工作流中充當一種“原料”。
2.  硃砂有毒。這個專案是為了 **猛、糙、快** (a.k.a. *Dirty and Quick*) 的目的而開發的，可能會產生意料之外的副作用（它並非完全無害）。
3.  硃砂是一種硫化汞 (HgS) 的礦物，呈深紅色，而 Ruby 也是一種深紅色的寶石。給一個 Ruby 專案取名為 “Cinnabar（硃砂）” 非常貼切。

## 快速上手

Github Actions for cinnabar

```yaml
env:
  # Speeds up script startup by disabling RubyGems
  RUBYOPT: "--disable=gems"
  default_ci_shell: ruby cinnabar/ci.rb {0}

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
