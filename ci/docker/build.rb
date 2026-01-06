# frozen_string_literal: true

def create_zstd_buildx_machine
  return if system('docker buildx create --use --name zstd')

  'WARNING: Failed to create/use zstd buildx instance (using default)'.log_warn
end

# build docker image
class DockerBuild
  DEFAULT = {
    docker_file: 'Dockerfile',
    docker_context: 'docker_tmp',
  }.freeze

  def initialize(options = {})
    options ||= {}
    opts = DEFAULT.merge(options)

    required_keys = %i[os arch tag docker_repo]
    missing_keys = required_keys.reject { |key| opts.key?(key) }
    required_keys.concat(%i[docker_context docker_file platform])

    raise ArgumentError, "Missing required options: #{missing_keys.join(', ')}" unless missing_keys.empty?

    @os, @arch, @tag, @docker_repo, @docker_context, @docker_file, @platform =
      opts.values_at(*required_keys)
  end

  def build # rubocop:disable Metrics/MethodLength
    require_relative 'build_cfg'
    require_relative 'platform_hash'

    platform_info = PlatformHash.platform_info(@os, @arch)

    config = {
      tag: @tag,
      # target: @target || platform_info[:target],
      platform: @platform || platform_info[:oci],
      file: @docker_file,
    }.compact

    BuildConfig
      .docker_build_options
      .merge(config.slice(:platform, :tag, :file))
      .merge(tag: "#{@docker_repo}:#{config[:tag]}")
      .to_argv
      .push(@docker_context)
      .run_cmd
  end
end
