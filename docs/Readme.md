# Cinnabar

## Preface

Q: Why is it named Cinnabar?  

A:

1. Cinnabar was an ingredient used by ancient Daoist alchemists in their elixirs, much like this project serves as an "ingredient" within CI workflows.  
2. Cinnabar is toxic. This project was developed for *Dirty and Quick* purposes and may produce unexpected side effects—in a sense, it is not entirely harmless.  
3. Cinnabar, a mineral form of mercury sulfide, is a deep red-colored stone. And ruby is also a deep red stone. Naming a Ruby project "Cinnabar" is particularly fitting.

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
          ref: cf1b9d3d48cf579fa1969b0d2453e6f859a2ae09

      - name: (example) run cargo command
        run: |
          {
            cargo: nil,
            build: nil,
            profile: 'release',
            verbose: true,
            target: 'x86_64-unknown-linux-musl'
          } 
            .then(&hash_to_argv)
            .then(&run)
```

See also: [build-wasi.yml](https://github.com/2moe/glossa/blob/dev/.github/workflows/build-wasi.yml)
