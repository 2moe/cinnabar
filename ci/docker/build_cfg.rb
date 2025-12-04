# frozen_string_literal: true

# --------------------
# Configuration Module
# --------------------
module BuildConfig
  module_function

  def buildkit_config
    {
      type: 'image',
      oci_mediatypes: true,
      compression: 'zstd',
      force_compression: false,
      compression_level: 18,
      attestation_inline: false,
    }.freeze
  end

  def docker_build_options
    {
      docker: nil,
      buildx: nil,
      build: nil,
      platform: 'wasi/wasm',
      output: convert_to_docker_output(buildkit_config),
      push: true,
      tag: '',
      # "#{DOCKER_CONTEXT_TMP}": nil
    }
  end

  # Converts a hash to Docker output format string
  def convert_to_docker_output(hash)
    hash.map { |key, value|
      "#{key.to_s.tr('_', '-')}=#{value}"
    }.join(',')
  end
end

# WASI_TARGETS = [
#   {
#     tag: 'wasi-p1',
#     target: 'wasm32-wasip1',
#     platform: 'wasip1/wasm',
#     file: 'ci/wasi.dockerfile'
#   },
#   {
#     tag: 'wasi-p2',
#     target: 'wasm32-wasip2',
#     platform: 'wasi/wasm',
#     file: 'ci/wasi.dockerfile'
#   }
# ].freeze
