# Cinnabar

[![Gem Version](https://badge.fury.io/rb/cinnabar.svg?icon=si%3Arubygems)](https://rubygems.org/gems/cinnabar)

专为 CI 流程打造的工具集。

---

| Language/語言                   | ID         |
| ------------------------------- | ---------- |
| 简体中文                        | zh-Hans-CN |
| [English](./Readme.md)          | en-Latn-US |
| [繁體中文](./Readme-zh-Hant.md) | zh-Hant-TW |

---

## 前言

**问：为何取名为 Cinnabar（朱砂）？**

**答：**

1.  朱砂是中国古代道教炼丹师在炼丹时使用的一种原料，就像这个项目在 CI 工作流中充当一种“原料”。
2.  朱砂有毒。这个项目是为了 **猛、糙、快** (a.k.a. *Dirty and Quick*) 的目的而开发的，可能会产生意料之外的副作用（它并非完全无害）。
3.  朱砂是一种硫化汞 (HgS) 的矿物，呈深红色，而 Ruby 也是一种深红色的宝石。给一个 Ruby 项目取名为 “Cinnabar（朱砂）” 非常贴切。

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
