# frozen_string_literal: true

# NOTE: This file can be run independently;
#   Although **00_pre.rb** has already imported the relevant libraries, they still need to be imported here.
require 'pathname'

module Cinnabar
  def self.to_path_proc = ->(dir) { Pathname(dir) }
end

module Cinnabar::StrToPath
  module Ext
    def to_path = ::Kernel.Pathname(self)
  end

  # @example
  #
  #     include Cinnabar::StrToPath::Mixin
  #
  #     __dir__.to_path
  #     # Same as `Pathname(__dir__)`
  module Mixin
    def self.included(_host) = ::String.include Ext
  end

  # @example
  #
  #     using Cinnabar::StrToPath::Refin
  #
  #     __dir__.to_path
  #     # Same as `Pathname(__dir__)`
  module Refin
    refine ::String do
      import_methods Ext
    end
  end
end

module Cinnabar::Path
  module_function

  def append_load_path(dir)
    $: << dir unless $:.include?(dir)
  end

  def find_and_append_load_path(gem_name = 'logger', cache_file: 'tmp/load_path.txt', max_retries: 2)
    pkg = gem_name.to_s
    cache_data = decode_cache_file(cache_file)
    case val = cache_data&.[](pkg)
      when nil then ()
      else return append_load_path(val)
    end

    lib_dir = gem_dir_with_retry(pkg, max_retries)

    cache_data[pkg] = lib_dir
    encoded = encode_cache_hash(cache_data)

    Kernel.Pathname(cache_file)
      .tap { _1.dirname.mkpath }
      .write(encoded)

    append_load_path(lib_dir)
  end

  def decode_cache_file(file)
    return {} unless File.exist?(file)

    File.foreach(file)
      .lazy
      .map(&:lstrip)
      .map(&:chomp)
      .reject(&:empty?)
      .reject { _1.start_with? '#' }
      .map { |line| line.split('  ', 2) }
      .to_h
  end

  def encode_cache_hash(data)
    Kernel.raise ArgumentError, 'data must be a hash' unless data.is_a? ::Hash

    data.map { |k, v| "#{k}  #{v}" }.join("\n")
  end

  def gem_dir(pkg)
    path = IO.popen(%w[gem which -V] << pkg.to_s, &:read).to_s.strip
    Kernel.raise "gem which returned empty for #{pkg}" if path.empty?

    File.dirname(path)
  end
  private_class_method :gem_dir

  def gem_dir_with_retry(gem_name, max_retries = 2)
    pkg = gem_name.to_s
    attempts = 0

    begin
      logger_dir = gem_dir(pkg)
    rescue StandardError => e
      Kernel.warn "[WARN] #{e}; Try installing #{pkg}"
      Kernel.system "gem install #{pkg}" or Kernel.raise 'Failed to install'

      attempts += 1
      Kernel.raise 'Already retried 3 times' if attempts > max_retries

      retry
    end
    logger_dir
  end
  # private_class_method :gem_dir_with_retry
end
