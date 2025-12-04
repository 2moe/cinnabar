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
  # optional values: debug, info, warn, error, fatal, unknown
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
          ref: v0.0.1

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
            .run_cmd
```

## Examples

### Command Runner

#### `.run_async`

```ruby,yaml
- run: |
    'building wasi file...'.log_dbg

    out_fd, waiter = {
      cargo: (),
      b: (),
      r: true,
      target: 'wasm32-wasip2'
    }
      .to_argv
      .run_async

    stdout, status = Cinnabar::Command.wait_with_output(out_fd, waiter)
    stdout.log_info
    raise "wasi" unless status.success?
```

#### `.run_async` + pass stdin data

```ruby,yaml
- run: |
    opts = {stdin_data: "Run in the background" }

    io_and_waiter =
      %w[wc -m].async_run(opts:)
        .then { Cinnabar::Command.wait_with_output *_1 }
```


#### `.run` + pass stdin data

```ruby,yaml
- run: |
    qmp_data = <<~'QMP_JSON'
      { "execute":"qmp_capabilities" }
      { "execute":"query-cpu-model-expansion",
        "arguments":{"type":"full","model":{"name":"host"}} }
      { "execute":"quit" }
    QMP_JSON

    accel = %w[kvm hvf tcg].join ':'
    opts = { stdin_data: qmp_data, allow_failure: true }

    stdout = {
      'qemu-system-aarch64': (),
      machine: "none,accel=#{accel}",
      cpu: 'host',
      display: 'none',
      nodefaults: true,
      no_user_config: true,
      qmp: 'stdio',
    } .to_argv_bsd
      .run(opts:)

    "stdout: #{stdout}".log_info
```
