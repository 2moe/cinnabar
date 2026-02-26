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

## Documentation

[![ClassDiagram](../misc/assets/svg/ClassDiagram.svg)](https://raw.githubusercontent.com/2moe/cinnabar/refs/heads/main/misc/assets/svg/ClassDiagram.svg)

- Github Pages: <https://2moe.github.io/cinnabar>
- [ChangeLog](./ChangeLog.md)

## Quick Start

Github Actions for cinnabar

![Image](https://github.com/user-attachments/assets/a4697c24-8e67-42fa-8363-d9267b3bcfb4)

```yaml
env:
  # Speeds up script startup by disabling RubyGems
  RUBYOPT: "--disable=gems"
  default_ci_shell: ruby cinnabar/ci.rb {0}
  # optional values: debug, info, warn, error, fatal, unknown
  RUBY_LOG: debug

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
          ref: v0.0.8

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

#### `.run` + pass stdin data

```ruby,yaml
- run: |
    opts = { stdin_data: "Hello", allow_failure: true }
    stdout = %w[wc -m].run(opts:)

    stdout.to_i == 5 #=> true
```

#### `.async_run` + log

```ruby,yaml
- run: |
    'building wasi file...'.log_dbg
    task = {
      cargo: (),
      b: (),
      r: true,
      target: 'wasm32-wasip2'
    } .to_argv
      .async_run

    # log_dbg, log_info, log_warn, log_err, log_fatal, log_unk
    "You can now do other things without waiting for
    the process to complete.".log_dbg

    stdout, status = task.wait_with_output
    stdout.log_info
    raise "wasi" unless status.success?
```

#### `.async_run` + pass stdin data

```ruby,yaml
- run: |
    stdin_data = <<~'QMP_JSON'
      { "execute":"qmp_capabilities" }
      { "execute":"query-cpu-model-expansion",
        "arguments":{"type":"full","model":{"name":"host"}} }
      { "execute":"quit" }
    QMP_JSON

    # opts = { stdin_data:, stdin_binmode: false }
    opts = { stdin_data: }

    accel = %w[kvm hvf whpx].join ':'
    task = {
      'qemu-system-x86_64': (),
      machine: "accel=#{accel}",
      cpu: 'host',
      display: 'none',
      nodefaults: true,
      no_user_config: true,
      qmp: 'stdio',
    } .to_argv_bsd
      .async_run(opts:)

    stdout, status = task.wait_with_output
    stdout.log_info if status.success?
```

### Downloader

```ruby,yaml
- run: |
    url = 'https://docs.ruby-lang.org/en/master'
    url.download
    # OR: url.download({out_dir: "/tmp", file_name: "index.html"})
```

### Function Pipe

```ruby,yaml
- run: |
    upper = ->s { s.upcase }

    'Foo'
      .▷(upper)
      .▷ :puts #=> "FOO"
```

### String To Pathname

```ruby,yaml
- run: |
    __dir__.to_path #  Same as Pathname(__dir__)
      .join('tmp')
```

### GemPath

`GemPath` is used mainly with Ruby started via the `--disable=gems` flag; the code below is equivalent to `%w[ irb rdoc reline ].each { require it }`.

```ruby
def require_gems = ->(gems) {
  {
    # cache_dir: File.expand_path('~/.cache/ruby'),
    gems:,
  }
    .then(&Cinnabar.new_gem_path_proc)
    .append_load_path!

  gems.each { require _1 }
}

%w[
  irb rdoc reline
].then(&require_gems)
```

#### Faster IRB

Because `GemPath` automatically caches gem `require_paths`, combining it with `ruby --disable=gems` can significantly reduce IRB startup time.

1. Run: [misc/firb/install.ps1](../misc/firb/install.ps1)

OR:

```pwsh
gem install cinnabar
```

2.
  - Enter the directory:
    - `ruby -r cinnabar -e "p Cinnabar.firb_path"`
    - OR: `${XDG_CACHE_HOME:-~/.cache}/ruby/firb/bin/` (POSIX sh)
    - OR: `~/.cache/ruby/firb/bin/`
    - OR: `%UserProfile%\.cache\ruby\firb\bin` (Windows CMD)

3. run
  - [`./firb0`](../misc/firb/bin/firb0)
  - OR [`.\firb0.bat`](../misc/firb/bin/firb0.bat) (Windows)
  - OR [`./firb`](../misc/firb/bin/firb)
  - OR `.\firb.bat` (Windows)
