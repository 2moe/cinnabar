# frozen_string_literal: true

# NOTE: This file can be run independently.

require 'pathname'

module Cinnabar
  # Returns a factory `Proc` that builds a {Cinnabar::GemPath} instance.
  #
  # This is useful when you want to defer initialization or inject a constructor-like
  # callable into other components (e.g., configuration objects, DI containers, hooks).
  #
  # ## Behavior
  #
  # - The returned `Proc` accepts a single argument `opts`.
  # - When called, it creates a new {Cinnabar::GemPath} with `opts`.
  #
  # @param opts [Hash] options forwarded to {Cinnabar::GemPath#initialize}
  # @option opts [String] :cache_dir base directory for the JSON cache
  # @option opts [String] :cache_file cache file name or absolute path
  # @option opts [Array<String,Symbol>] :gems gem names to resolve
  # @option opts [Boolean] :install_gem whether to auto-install missing gems
  #
  # @return [Proc] a callable object: `(opts) -> Cinnabar::GemPath`
  #
  # @example Build and use a resolver on demand
  #
  #     {
  #        gems: %w[rdoc logger irb reline fiddle],
  #        install_gem: true
  #     }.then(&Cinnabar.new_gem_path_proc)
  #      .append_load_path!
  #
  # @see Cinnabar::GemPath
  def self.new_gem_path_proc = ->(opts) { Cinnabar::GemPath.new(opts) }
end

# Low-level helpers for resolving RubyGems load paths.
#
# This module provides the "expensive" operations: loading RubyGems, locating gem specs, and
# optionally installing missing gems.
#
# ## Design goals
#
# - **Lazy-load RubyGems**: do not `require 'rubygems'` at file load time.
# - **Return full require paths**: use RubyGems’ resolved paths rather than hand-joining.
# - **Be usable by higher-level caches**: see {Cinnabar::GemPath}.
#
# @note These functions may perform disk I/O and can be slow.
module Cinnabar::GemPathCore
  module_function

  # Ensures RubyGems is loaded.
  #
  # @note If Ruby was not started with `--disable=gems` option, this function is unnecessary.
  #
  # @note This function **must** be called only at the point where RubyGems is
  #   actually needed (lazy loading).
  #
  # ## Behavior
  #
  # - If RubyGems is already available (`::Gem` and `Gem::Specification`), this is a no-op.
  # - Otherwise, it calls `require 'rubygems'`.
  #
  # @return [void]
  #
  # @note Do not call `require 'rubygems'` outside this method.
  def ensure_rubygems!
    return if defined?(::Gem) && ::Gem.respond_to?(:Specification)

    Kernel.require 'rubygems'
  end

  # Returns full load paths for a gem's require paths.
  #
  # This uses `Gem::Specification#full_require_paths`, which returns **absolute**
  # directories that should be added to `$LOAD_PATH` to require files from the gem.
  #
  # @param gem_name [String] gem name (e.g. `"logger"` or `:logger`)
  # @return [Array<String>] absolute require directories (e.g. `["/path/to/gems/foo/lib"]`)
  #
  # @raise [Gem::LoadError] if the gem is not installed / cannot be found
  # @example Get full require paths
  #   Cinnabar::GemPathCore.find_lib_paths("logger")
  def find_lib_paths(gem_name)
    ensure_rubygems!

    Gem::Specification.find_by_name(gem_name).full_require_paths
  end

  # Returns the gem's load paths; installs the gem when missing.
  #
  # This method is intended for low-level bootstrap scenarios:
  #
  # - Try to resolve require paths via RubyGems.
  # - If it fails, warn to stderr and attempt `Gem.install(gem)`.
  # - Re-resolve paths after successful installation.
  #
  # ## Notes
  #
  # - This method intentionally prints warnings via {Kernel.warn}.
  # - Avoid using "advanced" loggers here, because this method may run before
  #   other dependencies are available.
  #
  # @param gem_name [String, Symbol] gem name
  # @return [Array<String>] absolute require directories for the gem
  #
  # @raise [RuntimeError] if installation returns `nil` or an empty spec list
  # @raise [Exception] any error raised by RubyGems or filesystem operations
  #
  # @example Resolve paths, installing automatically if missing
  #
  #     logger_lib_paths = Cinnabar::GemPathCore.find_or_install_lib_paths("logger")
  def find_or_install_lib_paths(gem_name)
    ensure_rubygems!

    gem = gem_name.to_s
    begin
      find_lib_paths(gem)

    # NOTE: Intentionally rescuing `Exception` here (see original intent).
    rescue Exception => e # rubocop:disable Lint/RescueException
      Kernel.warn "[WARN] #{e}; Try installing #{gem}"

      # Attempt to install; raise if installation fails.
      specs = Gem.install(gem)
      Kernel.raise "Failed to install #{gem}" if specs.nil? || specs.empty?

      find_lib_paths(gem)
    end
  end

  # Builds a mapping from gem name to resolved load paths.
  #
  # @param gems [Array<String>] gem names
  # @param install_gem [Boolean] whether to attempt installing missing gems
  # @return [Hash{(String)=>Array<String>}] mapping: gem_name => full require paths
  #
  # @example Build a mapping without installing
  #   Cinnabar::GemPathCore.init_gem_dir_hash(%w[rdoc logger irb reline fiddle], install_gem: false)
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

# Cached resolver for gem load paths.
#
# {Cinnabar::GemPathCore} performs expensive operations (loading RubyGems, resolving specs,
# installing missing gems). This class adds a JSON cache layer to reuse results and
# avoid repeated slow calls.
#
# ## What it caches
#
# - A Hash mapping `gem_name => [full_require_paths...]`
# - Serialized to JSON on disk (see {#cache_file})
#
# ## Typical usage
#
# 1. Create an instance with a set of gems.
# 2. Call {#append_load_path!} to add those directories to `$LOAD_PATH`.
#
# @note Prefer using the cache whenever possible; RubyGems operations can be slow.
class Cinnabar::GemPath
  # Alias to the low-level implementation module.
  #
  # @return [Module]
  CoreMod = Cinnabar::GemPathCore

  require 'json'

  # The cache file path, gems list, and install behavior.
  #
  # @!attribute [rw] cache_file
  #   @return [Pathname] cache file path (`*.json`)
  #
  # @!attribute [rw] gems
  #   @return [Array<String>] normalized gem names (unique, non-empty)
  #
  # @!attribute [rw] install_gem
  #   @return [Boolean] whether missing gems should be installed automatically
  attr_accessor :cache_file, :gems, :install_gem

  # The in-memory cache hash.
  #
  # @return [Hash{String=>Array<String>}] gem name => full require paths
  attr_reader :cache_hash

  # Default options for initialization.
  #
  # @return [Hash]
  # @option cache_dir [String] directory to store cache file (default: `~/.cache/ruby`)
  # @option cache_file [String] file name or absolute path (default: `gem_path.json`)
  # @option gems [Array<String,Symbol>] gem names to manage
  # @option install_gem [Boolean] whether to auto-install missing gems
  DEFAULT_OPTS = {
    cache_dir: File.expand_path('~/.cache/ruby'),
    cache_file: 'gem_path.json',
    gems: [],
    install_gem: true,
  }.freeze

  # Creates a cache-backed gem path resolver.
  #
  # ## Behavior
  #
  # - Normalizes `gems` to unique, non-empty strings.
  # - If cache file exists, it is decoded and then refreshed:
  #   - Missing gems are generated and merged into the cache.
  #   - Broken entries (paths not existing) are regenerated.
  # - If no cache exists, it generates paths for all gems and writes the cache.
  #
  # @param opts [Hash] options overriding {DEFAULT_OPTS}
  # @option opts [String] :cache_dir
  # @option opts [String] :cache_file
  # @option opts [Array<String,Symbol>] :gems
  # @option opts [Boolean] :install_gem
  #
  # @return [Cinnabar::GemPath]
  #
  # @example Create and append load paths
  #
  #     gems = %w[rdoc logger irb reline fiddle]
  #
  #     { gems: }
  #       .then { Cinnabar::GemPath.new _1 }
  #       .append_load_path!
  def initialize(opts = {})
    options = DEFAULT_OPTS.merge(opts || {})

    gems, cache_dir, cache_file, @install_gem =
      options.values_at(:gems, :cache_dir, :cache_file, :install_gem)

    @gems = Array(gems).map(&:to_s).reject(&:empty?).uniq

    raise 'Empty @gems!' if @gems.empty?

    @cache_file = init_cache_file(cache_dir, cache_file)
    @cache_hash = {}

    if @cache_file.exist?
      decode_cache_file
      return
    end

    merge_generated_paths!(@gems)
  end

  # Writes the in-memory cache to disk.
  #
  # This serializes {#cache_hash} as JSON and persists it using an atomic write
  # strategy (see {#atomic_write_cache_file}).
  #
  # @return [void]
  def update_cache_file
    @cache_hash
      .then { JSON.dump _1 }
      .then { atomic_write_cache_file _1 }
  end

  # Appends cached gem paths into `$LOAD_PATH`.
  #
  # This is typically called after initialization. It will add each directory in the
  # cache for the configured gems to Ruby's load path.
  #
  # ## Notes
  #
  # - This is **idempotent**: it avoids inserting duplicates.
  # - It mutates the global `$LOAD_PATH` (`$:`).
  #
  # @return [void]
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

  # Writes cache content to disk atomically.
  #
  # It writes to a temporary file and renames it to the final cache path.
  # This reduces the chance of leaving a partially-written JSON file when the
  # process crashes or is interrupted mid-write.
  #
  # @param content [String] serialized JSON content
  # @return [void]
  #
  # @api private
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

  # Resolves the cache file path.
  #
  # - If `file` is absolute, it is used directly.
  # - Otherwise, it is resolved relative to `dir`.
  # - Ensures the directory exists (`mkpath`).
  #
  # @param dir [String, Pathname] base directory
  # @param file [String, Pathname] file name or absolute path
  # @return [Pathname] resolved cache file path
  #
  # @api private
  def init_cache_file(dir, file)
    f = Pathname(file)

    if f.absolute?
      f
    else
      Pathname(dir).join(f)
    end
      .tap { _1.dirname.mkpath }
  end

  # Attempts to decode the cache JSON file into a Hash.
  #
  # If decoding fails for any reason, it warns and removes the cache file, then
  # returns an empty hash.
  #
  # @return [Hash] decoded hash (or `{}` if decode fails)
  #
  # @note This method intentionally rescues `Exception` per the original design.
  # @api private
  def try_decode_cache_hash
    @cache_file
      .read
      .then { JSON.parse _1 }
  rescue Exception => e # rubocop:disable Lint/RescueException
    Kernel.warn "[WARN] Failed to decode json file; error: #{e}; unlink #{@cache_file}"
    @cache_file.unlink
    {}
  end

  # Decodes the cache file and refreshes any missing/broken entries.
  #
  # - Loads {#cache_hash} from disk.
  # - Generates entries for missing gems in {#gems}.
  # - Regenerates entries whose paths no longer exist on disk.
  #
  # @return [void]
  #
  # @api private
  def decode_cache_file
    @cache_hash = try_decode_cache_hash
    refresh_missing_gems!
    refresh_broken_gems!
  end

  # ===========
  private

  # Computes gems that are required but absent from the cache.
  #
  # @return [Array<String>]
  def missing_gems
    @gems - @cache_hash.keys
  end

  # Generates and merges cache entries for missing gems.
  #
  # @return [void]
  def refresh_missing_gems!
    gems = missing_gems
    return if gems.empty?

    merge_generated_paths!(gems)
  end

  # ===========

  # Computes gems whose cached paths are missing on disk.
  #
  # @return [Array<String>]
  def broken_gems
    @cache_hash
      .filter { |k, _| @gems.include? k }
      .reject { |_, v| all_paths_exist?(v) }
      .keys
  end

  # Checks whether all cached paths exist.
  #
  # @param values [Array<String>, Object] cached paths (normally an array)
  # @return [Boolean] true if all entries exist on disk
  def all_paths_exist?(values)
    Array(values).all? { File.exist? _1 }
  end

  # Regenerates and merges cache entries for broken gems.
  #
  # @return [void]
  def refresh_broken_gems!
    gems = broken_gems
    return if gems.empty?

    Kernel.warn "[INFO] update gem path, key: #{gems}"
    merge_generated_paths!(gems)
  end

  # ===========

  # Generates demonstrates gem paths via {CoreMod} and persists the updated cache.
  #
  # @param gems [Array<String>] gem names to generate
  # @return [void]
  #
  # @raise [Exception] any error raised by RubyGems resolution/installation
  def merge_generated_paths!(gems)
    h2 = CoreMod.init_gem_dir_hash(gems, install_gem: @install_gem)
    return if h2.empty?

    @cache_hash.merge! h2
    update_cache_file
  end
end
