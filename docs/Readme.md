# Cinnabar

## Usage

Github Actions for cinnabar

```yaml
env:
  # Speeds up script startup by disabling RubyGems
  RUBYOPT: "--disable=gems"
  default_ci_shell: ruby cinnabar/ci/preload.rb {0}

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: ${{env.default_ci_shell}}
    steps:
      - uses: actions/checkout@v4

      - name: clone cinnabar
        uses: actions/checkout@v4
        with:
          repository: 2moe/cinnabar
          path: cinnabar
          ref: 9bb73e96bb904c0b8f1ed82f3a7a58c5bb88eb39

      - name: hello world
        run: |
          pp `ls`
          p 'Hello World'
```

See also: [build-wasi.yml](https://github.com/2moe/glossa/blob/dev/.github/workflows/build-wasi.yml)
