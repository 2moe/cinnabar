# frozen_string_literal: true

# NOTE: This file can be run independently;
#   Although **00_pre.rb** has already imported the relevant libraries, they still need to be imported here.
require 'pathname'

module Cinnabar
  # Build a Proc that converts a directory-like value into a {Kernel.Pathname}.
  #
  # This is handy when you want to pass a converter into higher-order APIs
  # (e.g., map/filter pipelines).
  #
  # @param dir [String, #to_s] a directory path (or any object convertible to String)
  # @return [Proc] a lambda that maps `dir` to `Pathname(dir)`
  #
  # @example Convert a list of directories to Pathname objects
  #
  #     conv = Cinnabar.to_path_proc
  #     %w[/tmp /var].map(&conv)
  #     #=> [#<Pathname:/tmp>, #<Pathname:/var>]
  def self.to_path_proc = ->(dir) { Pathname(dir) }
end

# Adds `String#to_path` as a convenience helper to convert strings into {Kernel.Pathname}.
#
# This module supports two integration styles:
#
# - {Cinnabar::StrToPath::Mixin}: globally extends {String} (monkey patch).
# - {Cinnabar::StrToPath::Refin}: lexically-scoped extension via refinements.
#
# @note This feature relies on Ruby's {Pathname} class.
#   Make sure `require "pathname"` is loaded before calling `to_path`.
module Cinnabar::StrToPath
  # Implementation of the `#to_path` method intended to be mixed into {String}.
  module Ext
    # Convert the receiver (a String) into a {Pathname}.
    #
    # @return [Pathname] `Pathname(self)`
    #
    # @example
    #
    #     "lib".to_path
    #     #=> #<Pathname:lib>
    def to_path = ::Kernel.Pathname(self)
  end

  # This is a "mixin switch": `include Cinnabar::StrToPath::Mixin` will modify
  # {::String} for the entire process (i.e., a monkey patch).
  #
  # @note Side effect: this will affect *all* strings in the process, including
  #   third-party code. If you want scoped behavior, prefer {Refin}.
  #
  # @example
  #
  #     include Cinnabar::StrToPath::Mixin
  #
  #     __dir__.to_path
  #     # Same as `Pathname(__dir__)`
  module Mixin
    # Hook invoked when this module is included.
    #
    # @param _host [Module] the including host (unused)
    # @return [void]
    def self.included(_host) = ::String.include Ext
  end

  # Adds `String#to_path` via Ruby refinements (lexically scoped).
  #
  # This avoids global monkey patches. The method is only visible within scopes
  # where `using Cinnabar::StrToPath::Refin` is active.
  #
  # @example
  #
  #     using Cinnabar::StrToPath::Refin
  #
  #     __dir__.to_path
  #     # Same as `Pathname(__dir__)`
  module Refin
    # Refinement for {String} to import {Ext#to_path}.
    refine ::String do
      import_methods Ext
    end
  end
end

module Cinnabar::Path
  module_function

  # Appends a directory to Ruby's load path (`$LOAD_PATH` / `$:`)
  # if it is not already included.
  #
  # @param dir [String] directory path to add into `$LOAD_PATH`
  # @return [void]
  # @example
  #
  #     Cinnabar::Path.append_load_path '/opt/ruby/4.0.0/lib/ruby/4.0.0'
  def append_load_path(dir)
    # $: is an alias of $LOAD_PATH
    $: << dir unless $:.include?(dir)
  end

  # Finds the gem's "lib directory" (via `gem which -V`) and append it to $LOAD_PATH.
  #
  # This method maintains a small cache file to avoid running `gem which` repeatedly.
  # Cache format (per line):
  #   <gem_name><two spaces><lib_dir>
  #
  # If the gem cannot be located, it will try to install it and retry up to `max_retries`.
  #
  # @param gem_name [String, #to_s] gem name to locate (default: 'logger')
  # @param cache_file [String] cache file path (default: 'tmp/load_path.txt')
  # @param max_retries [Integer] maximum retries for gem install + re-check (default: 2)
  # @return [void]
  def find_and_append_load_path(gem_name = 'logger', cache_file: 'tmp/load_path.txt', max_retries: 2)
    pkg = gem_name.to_s
    cache_data = decode_cache_file(cache_file)

    # If cached, append immediately and return.
    case val = cache_data&.[](pkg)
      when nil then ()
      else return append_load_path(val)
    end

    # Locate the gem's lib directory, installing the gem if necessary.
    lib_dir = gem_dir_with_retry(pkg, max_retries)

    # Update cache and write it back to disk.
    cache_data[pkg] = lib_dir
    encoded = encode_cache_hash(cache_data)

    # Ensure parent directory exists, then write the cache file.
    Kernel.Pathname(cache_file)
      .tap { _1.dirname.mkpath }
      .write(encoded)

    # Finally, append the located directory to $LOAD_PATH.
    append_load_path(lib_dir)
  end

  # Decodes cache file into a Hash.
  #
  # It ignores:
  #
  # - leading spaces (lstrip)
  # - empty lines
  # - comment lines that start with '#'
  #
  # Each line is split by "two spaces" into:
  #   `key  value`
  #
  # @param file [String] cache file path
  # @return [Hash{String => String}] mapping from gem name to lib dir
  def decode_cache_file(file)
    # If cache file does not exist, treat as empty cache.
    return {} unless File.exist?(file)

    File.foreach(file)
      .lazy
      .map(&:lstrip)                  # allow indentation; normalize leading spaces
      .map(&:chomp)                   # remove trailing newline
      .reject(&:empty?)               # drop blank lines
      .reject { _1.start_with? '#' }  # drop comments
      .map { |line| line.split('  ', 2) } # split into [key, value] by two spaces
      .to_h
  end

  # Encodes a Hash into the cache file format.
  #
  # @param data [Hash] mapping from gem name to lib dir
  # @return [String] encoded cache content
  # @raise [ArgumentError] if `data` is not a Hash
  #
  # @example
  #
  #     CiPath = Cinnabar::Path
  #
  #     gem_home = "#{Dir.home}/.local/share/gem"
  #     data = {
  #       "logger" => "#{gem_home}/gems/logger-1.7.0/lib",
  #       "irb" => "#{gem_home}/gems/irb-1.16.0/lib",
  #       "reline" => "#{gem_home}/gems/reline-0.6.3/lib",
  #     }
  #     str = CiPath.encode_cache_hash(data)
  def encode_cache_hash(data)
    Kernel.raise ArgumentError, 'data must be a hash' unless data.is_a? ::Hash

    # Use "two spaces" as a stable delimiter (same as decode).
    data.map { |k, v| "#{k}  #{v}" }.join("\n")
  end

  # Resolves gem's lib directory by invoking:
  #     `gem which -V <pkg>`
  #
  # `gem which -V` prints the resolved file path; we strip it and take its dirname.
  #
  # @param pkg [String] gem name
  # @return [String] directory containing the resolved file
  # @raise [RuntimeError] if gem which returns empty
  #
  # @note Please do not use `Gem::Specification` in this method,
  # as this function and the script must remain compatible with `--disable=gems`.
  def gem_dir(pkg)
    path = IO.popen(%w[gem which -V] << pkg.to_s, &:read).to_s.strip
    Kernel.raise "gem which returned empty for #{pkg}" if path.empty?

    File.dirname(path)
  end
  private_class_method :gem_dir

  # Locates the lib directory for the given gem_name; if it fails, retries by installing the gem.
  #
  # Behavior:
  #
  # - If `gem_dir` raises, print a warning and run `gem install <pkg>`.
  # - Retry up to `max_retries`.
  #
  # @param gem_name [String, Symbol] gem name
  # @param max_retries [Integer] max retry count (default: 2)
  # @return [String] resolved lib directory
  # @raise [RuntimeError] when install fails or retries exceed max
  #
  #
  # @example
  #
  #     CiPath = Cinnabar::Path
  #
  #     dir_str = CiPath.gem_dir_with_retry("logger")
  def gem_dir_with_retry(gem_name, max_retries = 2)
    pkg = gem_name.to_s
    attempts = 0

    begin
      logger_dir = gem_dir(pkg)
    rescue StandardError => e
      # Inform user about the failure and the planned automatic install attempt.
      #
      # Do not use `Sinlog.warn` or any "advanced" logger here!
      # As this function is intended for lower-level APIs.
      Kernel.warn "[WARN] #{e}; Try installing #{pkg}"

      # Attempt to install; raise if installation fails.
      Kernel.system "gem install #{pkg}" or Kernel.raise 'Failed to install'

      attempts += 1
      Kernel.raise 'Already retried 3 times' if attempts > max_retries

      retry
    end

    logger_dir
  end
  # private_class_method :gem_dir_with_retry
end
