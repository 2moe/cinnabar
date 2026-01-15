# frozen_string_literal: true

# NOTE: This file can be run independently;

require 'pathname'

module Cinnabar
  def self.gem_paths_proc =->(opts) {
    Cinnabar::GemPath.new opts
  }
end

module Cinnabar::GemPathCore
  module_function

  # @note Since `require 'rubygems'` is expensive when the interpreter was started with `--disable=gems`,
  # do not call it outside this method; only invoke it inside.
  def ensure_rubygems!
    return if defined?(::Gem) && ::Gem.respond_to?(:Specification)

    Kernel.require 'rubygems'
  end

  def find_lib_paths(gem_name)
    ensure_rubygems!

    Gem::Specification.find_by_name(gem_name).full_require_paths
  end

  # Locates the lib directory for the given gem_name; if it fails, install the gem.
  #
  # @note If `req_paths` raises, print a warning and run `gem install <gem_name>`.
  #
  # @param gem_name [String, Symbol] gem name
  # @return [String] resolved lib directory
  # @raise [RuntimeError] when install fails
  #
  # @example
  #
  #     logger_lib_paths = Cinnabar::GemPath.find_or_install_lib_paths("logger")
  def find_or_install_lib_paths(gem_name)
    ensure_rubygems!

    gem = gem_name.to_s
    begin
      find_lib_paths(gem)

    # use `Exception` instead of `StandardError`
    rescue Exception => e # rubocop:disable Lint/RescueException
      # Inform user about the failure and the planned automatic install attempt.
      #
      # Do not use `Sinlog.warn` or any "advanced" logger here!
      # As this function is intended for lower-level APIs.
      Kernel.warn "[WARN] #{e}; Try installing #{gem}"

      # Attempt to install; raise if installation fails.
      specs = Gem.install(gem)
      Kernel.raise "Failed to install #{gem}" if specs.nil? || specs.empty?

      find_lib_paths(gem)
    end
  end

  def init_gem_dir_hash(gems, install_gem: true)
    gems.map { |name|
      paths =
        if install_gem
          find_or_install_lib_paths(name)
        else
          find_lib_paths(name)
        end

      [name, paths]
    }.to_h
  end
end

# @note We should reuse cached data as much as possible instead of fetching via `GemPathCore`.
# Operations within `GemPathCore` are expensive (slow).
class Cinnabar::GemPath
  CoreMod = Cinnabar::GemPathCore
  require 'json'

  attr_accessor :cache_file, :gems, :install_gem
  attr_reader :cache_hash

  DEFAULT_OPTS = {
    cache_dir: File.expand_path('~/.cache/ruby'),
    cache_file: 'gem_path.json',
    gems: [],
    install_gem: true,
  }.freeze

  def initialize(opts = {})
    options = DEFAULT_OPTS.merge(opts || {})

    gems, cache_dir, cache_file, @install_gem =
      options.values_at(:gems, :cache_dir, :cache_file, :install_gem)

    @gems = gems.map(&:to_s).reject(&:empty?).uniq

    @cache_file = init_cache_file(cache_dir, cache_file)
    @cache_hash = {}

    if @cache_file.exist?
      decode_cache_file
      return
    end

    merge_generated_paths!(@gems)
  end

  def update_cache_file
    @cache_hash
      .then { JSON.dump _1 }
      .then { atomic_write_cache_file _1 }
  end

  def append_load_path!
    @cache_hash
      .filter { |k, _| @gems.include? k.to_s }
      .each_value do |vals|
        Array(vals).each do |dir|
          # $: is $LOAD_PATH
          $:.push(dir) unless $:.include?(dir) # rubocop:disable Style/SpecialGlobalVars
        end
      end
  end

  protected

  def atomic_write_cache_file(content)
    path = @cache_file.to_s
    tmp = "#{path}.tmp.#{$$}" # rubocop:disable Style/SpecialGlobalVars
    begin
      File.write(tmp, content)
      File.rename(tmp, path)
    ensure
      File.unlink(tmp) rescue nil
    end
  end

  def init_cache_file(dir, file)
    f = Pathname(file)

    if f.absolute?
      f
    else
      Pathname(dir).join(f)
    end
      .tap { _1.dirname.mkpath }
  end

  def try_decode_cache_hash
    @cache_file
      .read
      .then { JSON.parse _1 }
  rescue Exception => e # rubocop:disable Lint/RescueException
    Kernel.warn "[WARN] Failed to decode json file; error: #{e}; unlink #{@cache_file}"
    @cache_file.unlink
    {}
  end

  def decode_cache_file
    @cache_hash = try_decode_cache_hash
    refresh_missing_gems!
    refresh_broken_gems!
  end

  # ===========
  private

  def missing_gems
    @gems - @cache_hash.keys
  end

  def refresh_missing_gems!
    gems = missing_gems
    return if gems.empty?

    merge_generated_paths!(gems)
  end

  # ===========

  def broken_gems
    @cache_hash
      .reject { |_, v| all_paths_exist?(v) }
      .keys
  end

  def all_paths_exist?(values)
    Array(values).all? { File.exist? _1 }
  end

  def refresh_broken_gems!
    gems = broken_gems
    return if gems.empty?

    Kernel.warn "[INFO] update gem path, key: #{gems}"
    merge_generated_paths!(gems)
  end

  # ===========

  def merge_generated_paths!(gems)
    h2 = CoreMod.init_gem_dir_hash(gems, install_gem: @install_gem)
    return if h2.empty?

    @cache_hash.merge! h2
    update_cache_file
  end
end
