# frozen_string_literal: true

require 'fileutils'

# Compresses file
class FileCompressor
  DEFAULT = {
    # tag: 'wasi-p2',
    # target: 'wasm32-wasip2',
    # pkg_name: 'glossa-cli',
    # suffix: '.wasm',
    docker_context: 'docker_tmp',
    cargo_build_profile: 'thin'
  }.freeze

  def initialize(options = nil)
    options ||= {}
    opts = DEFAULT.merge(options)

    required_keys = %i[tag target pkg_name suffix docker_context cargo_build_profile]
    missing_keys = required_keys.reject { |key| opts.key?(key) }

    raise ArgumentError, "Missing required options: #{missing_keys.join(', ')}" unless missing_keys.empty?

    @tag, @target, @pkg_name, @suffix, @docker_context, @cargo_build_profile =
      opts.values_at(*required_keys)
  end

  # -> dest_file
  def prepare_file
    create_directories
    source_path = prepare_source_file
    prepare_destination_file(source_path)
  end

  def compress
    run_zstd_compression(prepare_file)
  end

  def run_pigz(file_path, format = 'gz')
    cmd = %w[pigz -11 -v]
    cmd << '--zip' if format == 'zip'
    cmd << file_path
    cmd.then(&run)
  end

  def run_zstd_compression(file_path) # rubocop:disable Metrics/MethodLength
    {
      zstd: nil,
      "-T0": nil,   # Multithreaded compression
      rm: true,     # Delete input file after success
      force: true,
      verbose: true,
      "-19": nil    # Compression level
    }
      .then(&hash_to_args)
      .concat([file_path, '-o', "#{file_path}.zst"])
      .then(&run_in_bg)
  end

  def create_directories
    fs = FileUtils
    fs.mkdir_p(@docker_context)
    fs.mkdir_p('release')
  end

  def prepare_source_file
    target_dir = ENV['CARGO_TARGET_DIR'] || 'target'
    source = "#{target_dir}/#{@target}/#{@profile}/#{@pkg_name}#{@suffix}"

    FileUtils.cp(source, @docker_context)

    # Handle non-WASM files (create tar archive)
    if @suffix.to_s.empty?
      tar_file = "#{source}.tar"
      %W[tar --posix -cvf #{tar_file} #{source}].then(&run)
      return tar_file
    end
    source
  end

  def prepare_destination_file(source)
    suffix =
      if File.extname(source) == '.tar'
        '.tar'
      else
        @suffix
      end
    dest = "release/#{@tag}#{suffix}"
    FileUtils.cp(source, dest)
    dest
  end
end
