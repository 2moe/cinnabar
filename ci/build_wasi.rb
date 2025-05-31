def add_wasi_target
  [1, 2]
    .map { "wasm32-wasip#{_1}" }
    .map { %w[rustup target add] << _1 }
    .each(&run)
end

def build_wasi_p2(cargo_opts)
  cargo_opts
    .then(&hash_to_args)
    .then(&run)
end

def build_wasi_p1(cargo_opts)
  locales = %w[
    zh en en-GB fr ru ar de es pt hi bn ja
  ].map { "l10n-#{_1}" }

  {
    target: 'wasm32-wasip1',
    no_default_features: true,
    features:
      %w[json5 yaml ron]
        .concat(locales)
        .join(',')
  }
    .then { cargo_opts.merge _1 }
    .then(&hash_to_args)
    .then(&run)
end

def build_wasi_target(profile = 'thin')
  cargo_cfg = {
    cargo: nil,
    build: nil,
    package: 'glossa-cli',
    profile: profile,
    target: 'wasm32-wasip2',
    no_default_features: false,
    features: []
  }

  # wasi-p2:
  build_wasi_p2(cargo_cfg)

  # -------
  # wasi-p1:
  build_wasi_p1(cargo_cfg)
end

add_wasi_target
