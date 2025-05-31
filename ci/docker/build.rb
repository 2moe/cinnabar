# frozen_string_literal: true

def create_zstd_buildx_machine
  return if system('docker buildx create --use --name zstd')

  warn 'WARNING: Failed to create/use zstd buildx instance (using default)'
end

# build docker image
class DockerBuild
  DEFAULT = {
    docker_file: 'Dockerfile'
  }.freeze

  def initialize(options = {})
    options ||= {}
    opts = DEFAULT.merge(options)

    required_keys = %i[os arch tag docker_repo docker_context]
    missing_keys = required_keys.reject { |key| opts.key?(key) }
    required_keys.concat(%i[docker_file platform])

    raise ArgumentError, "Missing required options: #{missing_keys.join(', ')}" unless missing_keys.empty?

    @os, @arch, @tag, @docker_repo, @docker_context, @docker_file, @platform =
      opts.values_at(*required_keys)
  end

  def build # rubocop:disable Metrics/MethodLength
    require_ci 'docker/platform_hash'
    require_ci 'docker/build_cfg'

    platform_info = PlatformHash.platform_info(@os, @arch)

    config = {
      tag: @tag,
      # target: @target || platform_info[:target],
      platform: @platform || platform_info[:oci],
      file: @docker_file
    }.compact

    BuildConfig
      .docker_build_options
      .merge(config.slice(:platform, :tag, :file))
      .merge(tag: "#{@docker_repo}:#{config[:tag]}")
      .then(&hash_to_args)
      .push(@docker_context)
      .then(&run)
  end
end
