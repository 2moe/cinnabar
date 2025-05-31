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
          ref: bc5d92011886d8543515ce8ea0913e07be7849a2

      - name: (example) run cargo command
        run: |
          {
            cargo: nil,
            build: nil,
            profile: 'release',
            verbose: true,
            target: 'x86_64-unknown-linux-musl'
          }.then(&run)
```

See also: [build-wasi.yml](https://github.com/2moe/glossa/blob/dev/.github/workflows/build-wasi.yml)
