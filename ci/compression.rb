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
    cargo_build_profile: 'thin',
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

    require_relative 'docker/platform_hash'
    platform_info = PlatformHash.platform_info(@os, @arch)

    @target = opts[:target] || platform_info[:target]
  end

  # -> dest_file
  def prepare_file
    source_path = prepare_source_file
    prepare_destination_file(source_path)
  end

  # -> pid
  def compress(format = 'zstd') # rubocop:disable Metrics/MethodLength
    case format
      when 'zstd'
        run_zstd(prepare_file)
      when 'zopfli-zip'
        run_pigz(prepare_file, 'zip')
      when 'zip'
        run_7z(src_files: [prepare_file])
      when '7z'
        file = prepare_file
        run_7z(src_files: [file], dst_file: "#{file}.7z")
      else
        run_pigz(prepare_file)
    end
  end

  def create_directories
    fs = FileUtils
    fs.mkdir_p(@docker_context)
    fs.mkdir_p('release')
  end

  # -> cargo_target_file
  # old_name: copy_cargo_target_file_to_docker_context_dir
  def cp_target_file_to_context
    create_directories

    target_dir = ENV['CARGO_TARGET_DIR'] || 'target'
    "#{target_dir}/#{@target}/#{@cargo_build_profile}/#{@pkg_name}#{@suffix}"
      .then { File.realpath(_1) }
      .tap { FileUtils.cp(_1, @docker_context) }
  end

  def prepare_source_file
    source = cp_target_file_to_context

    # Handle no-suffix files (create tar archive)
    if @suffix.to_s.empty?
      tar_file = "#{source}.tar"
      run_tar(tar_file: tar_file, src_files: [source])
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

def run_tar(tar_file: 'a.tar', src_files: [])
  %W[tar --posix -cvf #{tar_file}]
    .concat(src_files)
    .run_cmd
end

# @return [Array(IO, Process::Waiter)]
def run_zstd(file_path) # rubocop:disable Metrics/MethodLength
  {
    zstd: nil,
    "-T0": nil,   # Multithreaded compression
    rm: true,     # Delete input file after success
    force: true,
    verbose: true,
    "-19": nil, # Compression level
  }
    .to_argv
    .concat([file_path, '-o', "#{file_path}.zst"])
    .async_run
end

# @return [Array(IO, Process::Waiter)]
def run_pigz(file_path, format = 'gz')
  cmd = %w[pigz -11 -kfv]
  cmd << '--zip' if format == 'zip'
  cmd << file_path
  cmd.async_run
end

# - src_files: Array[String], e.g., ['file1.txt', 'file2.txt']
# - dst_file: String, e.g., 'archive.zip
#
# @return [Array(IO, Process::Waiter)]
def run_7z(src_files:, dst_file: nil, num_of_threads: 4, use_deflate64: false) # rubocop:disable Metrics/MethodLength
  dst_file ||= "#{File.basename(src_files.first)}.zip"
  ext = File.extname(dst_file).downcase[1..]

  algo =
    if ext == 'zip'
      use_deflate64 ? 'Deflate64' : 'Deflate'
    else
      'lzma'
    end

  %W[7z a -t#{ext} -mm=#{algo} -mmt#{num_of_threads} -mx9]
    .push(dst_file)
    .concat(src_files)
    .async_run
end
