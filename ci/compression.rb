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

  def initialize(options = nil) # rubocop:disable Metrics/AbcSize
    options ||= {}
    opts = DEFAULT.merge(options)

    required_keys = %i[os arch tag pkg_name suffix]
    missing_keys = required_keys.reject { |key| opts.key?(key) }
    required_keys.concat(%i[docker_context cargo_build_profile])

    raise ArgumentError, "Missing required options: #{missing_keys.join(', ')}" unless missing_keys.empty?

    @os, @arch, @tag, @pkg_name, @suffix, @docker_context, @cargo_build_profile =
      opts.values_at(*required_keys)

    require_ci 'docker/platform_hash'
    platform_info = PlatformHash.platform_info(@os, @arch)

    @target = opts[:target] || platform_info[:target]
  end

  # -> dest_file
  def prepare_file
    source_path = prepare_source_file
    prepare_destination_file(source_path)
  end

  # -> pid
  def compress(format = 'zstd')
    case format
    when 'zstd'
      run_zstd_compression(prepare_file)
    when 'zip'
      run_pigz_compression(prepare_file, 'zip')
    else
      run_pigz_compression(prepare_file)
    end
  end

  # -> pid
  def run_pigz_compression(file_path, format = 'gz')
    cmd = %w[pigz -11 -kfv]
    cmd << '--zip' if format == 'zip'
    cmd << file_path
    cmd.then(&run_in_bg)
  end

  # -> pid
  # sig { returns(Integer) }
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

  # -> cargo_target_file
  def copy_cargo_target_file_to_docker_context_dir
    create_directories

    target_dir = ENV['CARGO_TARGET_DIR'] || 'target'
    "#{target_dir}/#{@target}/#{@cargo_build_profile}/#{@pkg_name}#{@suffix}"
      .then { File.realpath(_1) }
      .tap { FileUtils.cp(_1, @docker_context) }
  end

  def prepare_source_file
    source = copy_cargo_target_file_to_docker_context_dir

    # Handle no-suffix files (create tar archive)
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

# - src_files: Array[String], e.g., ['file1.txt', 'file2.txt']
# - dst_file: String, e.g., 'archive.zip
#
# -> pid
def run_7z(dst_file:, src_files:, num_of_threads: 4, use_deflate64: false)
  ext = File.extname(dst_file)[1..]

  algo =
    if ext == 'zip'
      use_deflate64 ? 'Deflate64' : 'Deflate'
    else
      'lzma'
    end

  %W[7z a -t#{ext} -mm=#{algo} -mmt#{num_of_threads} -mx9 $zip_file]
    .concat(src_files)
    .then(&run_in_bg)
end
