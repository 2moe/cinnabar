# rubocop:disable Style/Lambda, Lint/MissingCopEnableDirective
# typed: true
# frozen_string_literal: true

# ------------------
# Converts hash to command array
#
# @example
#
#   { cargo: nil, b: nil, r: true, target: "wasm32-wasip2" }
#     .then(&Argvise.new_proc)
#     .with_bsd_style(false)
#     .build
#     .display
#
#   #=> ["cargo", "b", "-r", "--target", "wasm32-wasip2"]
#
# # Conversion Rules:
#
# ## GNU Style:
#   - Boolean values:
#     - `{ verbose: true }` => ["--verbose"]
#     - `{ v: true }` => ["-v"]
#     - `{ v: false }` => [] #no argument generated
#   - String values:
#     - `{ f: "a.txt" }` => ["-f", "a.txt"]
#     - `{ file: "a.txt" }` => ["--file", "a.txt"]
#   - Array values:
#     - `{ t: ["a", "b"] }` => `["-t", "a", "-t", "b"]`
#     - `{ tag: %w[a b] }` => `["--tag", "a", "--tag", "b"]`
#   - Hash values:
#     - `{ L: { env: 'test' } }` => `["-L", "env=test"]`
#     - `{ label: { env: 'test' } }` => `["--label", "env=test"]`
#
# ## BSD Style:
#   - Boolean values:
#     - `{ verbose: true }` => ["-verbose"]
#     - `{ v: true }` => ["-v"]
#     - `{ v: false }` => [] #no argument generated
#   - String values:
#     - `{ f: "a.txt" }` => ["-f", "a.txt"]
#     - `{ file: "a.txt" }` => ["-file", "a.txt"]
#   - Array values:
#     - `{ t: ["a", "b"] }` => `["-t", "a", "-t", "b"]`
#     - `{ tag: %w[a b] }` => `["-tag", "a", "-tag", "b"]`
#   - Hash values:
#     - `{ L: { env: 'test' } }` => `["-L", "env=test"]`
#     - `{ label: { env: 'test' } }` => `["-label", "env=test"]`
#
# ## Common:
#   - Raw values:
#   - `{ cargo: nil, b: nil}` => `["cargo", "b"]`
#   - `{ "-fv": nil}` => `["-fv"]`
#
# ## About kebab_case_flags:
#   - `with_kebab_case_flags(true)`:
#     - `{enable_jit: true}` =>
#         - GNU-style: `["--enable-jit"]`
#         - BSD-style: `["-enable-jit"]`
#   - `with_kebab_case_flags(false)`:
#     - `{enable_jit: true}` =>
#         - GNU-style: `["--enable_jit"]`
#         - BSD-style: `["-enable_jit"]`
class Argvise
  attr_accessor :bsd_style, :kebab_case_flags

  # v0.0.3 default options
  DEFAULT_OPTS = { bsd_style: false, kebab_case_flags: true }.freeze

  class << self
    # Converts a hash into a command-line argument array
    #
    # @example
    #   require 'argvise'
    #   cmd = { ruby: nil, r: "argvise", verbose: true, e: true, "puts Argvise::VERSION": nil }
    #   opts = { bsd_style: false }
    #   Argvise.build(cmd, opts:)
    #
    # @param raw_cmd_hash [Hash] The hash to be converted (i.e., raw input data)
    # @param opts [Hash]
    # @see #initialize
    #
    # @return [Array<String>] The generated array of command-line arguments
    def build(
      raw_cmd_hash,
      opts: nil
    )
      opts ||= DEFAULT_OPTS
      new(raw_cmd_hash, opts:).build
    end

    # Returns a Proc that wraps `Argvise.new`, allowing functional-style chaining.
    #
    # Useful for transforming a hash of CLI arguments into a command array.
    #
    # @example
    #
    #     require 'argvise'
    #     { ruby: nil, r: "argvise", e: true, "puts Argvise::VERSION": nil }
    #       .then(&Argvise.new_proc)
    #       .build
    #       .then{system *_1}
    #
    # @see #initialize
    # @return [::Proc] `.call(raw_cmd_hash)` => self
    def new_proc
      ->(raw_cmd_hash) do
        new(raw_cmd_hash)
      end
    end
    # ----
  end

  # @example
  #
  #   require 'argvise'
  #   cmd = { ruby: nil, r: "argvise", verbose: true, e: true, "puts Argvise::VERSION": nil }
  #   opts = Argvise::DEFAULT_OPTS
  #   Argvise.new(cmd, opts:).build.then{system *_1}
  #
  # @param opts [Hash]: { bsd_style: Boolean, kebab_case_flags: Boolean }
  #
  # ## opts
  #
  # - When `bsd_style` is set to `false`, the builder operates in **GNU-style mode**,
  #   which typically uses hyphenated flags.
  #
  # - If `kebab_case_flags` is set to `true`, any underscores (`_`) in flag names
  #   will be automatically converted to hyphens (`-`).
  #   - For example, a flag like `--enable_jit` will be transformed into `--enable-jit`.
  #
  # When the value of a flag key is `nil`, the `kebab_case_flags` option has no effect.
  # — i.e., the key will not be transformed.
  #
  # For example, the input `{"a_b-c": nil}` will result in `["a_b-c"]`,
  # and **not** be automatically transformed into `["a-b-c"]`.
  def initialize(
    raw_cmd_hash,
    opts: nil
  )
    opts = DEFAULT_OPTS.merge(opts || {})

    @raw_cmd_hash = raw_cmd_hash
    @bsd_style = opts[:bsd_style]
    @kebab_case_flags = opts[:kebab_case_flags]
  end

  # Default: true
  # @return [self]
  def with_bsd_style(value = true) # rubocop:disable Style/OptionalBooleanParameter
    @bsd_style = value
    self
  end

  # Default: true
  # @return [self]
  def with_kebab_case_flags(value = true) # rubocop:disable Style/OptionalBooleanParameter
    @kebab_case_flags = value
    self
  end

  # @return [Array<String>]
  def build
    # @raw_cmd_hash.each_pair.flat_map { |k, v| process_pair(k.to_s, v) }
    @raw_cmd_hash.each_with_object([]) do |(k, v), memo|
      memo.concat(process_pair(k.to_s, v))
    end
  end

  private

  # Processes a single key-value pair and generates the corresponding argument fragment
  def process_pair(key, value)
    # e.g., {cargo: nil, build: nil} => ["cargo", "build"]
    return [key] if value.nil?
    # e.g., {install: false} => []
    return [] unless value

    flag = build_flag(key)
    generate_args(flag, value)
  end

  # Builds the command-line flag prefix (automatically detects short or long raw_cmd_hash)
  #
  # GNU Style:
  #  - short key, e.g., {v: true} => "-v"
  #  - long key, e.g., {verbose: true} => "--verbose"
  #
  # BSD Style:
  #  - short key, e.g., {verbose: true} => "-verbose"
  #  - no long key
  #
  # kebab_case_flags==true:
  #  - "_" => "-"
  #  - e.g., {enable_jit: true} =>
  #    - BSD-style: "-enable-jit"
  #    - GNU-style: "--enable-jit"
  #
  # kebab_case_flags==false:
  #  - e.g., {enable_jit: true} =>
  #    - BSD-style: "-enable_jit"
  #    - GNU-style: "--enable_jit"
  def build_flag(key) # rubocop:disable Metrics/MethodLength
    prefix =
      if @bsd_style
        '-'
      else
        key.length == 1 ? '-' : '--'
      end

    flag =
      if @kebab_case_flags
        key.tr('_', '-')
      else
        key
      end

    "#{prefix}#{flag}"
  end

  # Generates the corresponding argument array based on the value type
  def generate_args(flag, value)
    case value
      when true
        [flag]
      when Array
        expand_array(flag, value)
      when Hash
        expand_hash(flag, value)
      else
        # e.g., {tag: 'uuu'} => ["--tag", "uuu"]
        [flag, value.to_s]
    end
  end

  #     {tag: ["v1", "v2"]}
  #       => (flag: "--tag", array: ['v1', 'v2'])
  #       =>  ["--tag", "v1", "--tag", "v2"]
  def expand_array(flag, array)
    # FP style: array.flat_map { |v| [flag, v.to_s] }
    array.each_with_object([]) do |v, memo|
      memo << flag
      memo << v.to_s
    end
  end

  # Processes hash values (generates key=value format)
  #
  #     {label: { env: "test", key: "value" }}
  #       => (flag: "--label", hash)
  #       => ["--label", "env=test", "--label", "key=value"]
  def expand_hash(flag, hash)
    # hash.flat_map { |k, v| [flag, "#{k}=#{v}"] }
    hash.each_with_object([]) do |(k, v), memo|
      memo << flag
      memo << "#{k}=#{v}"
    end
  end
end

class Argvise
  # The foundation of {HashRefin} and {HashMixin}
  module HashExt
    # Converts a hash map into GNU-style command-line arguments.
    #
    # @param opts [Hash, nil] See also `Argvise.new`
    #
    # @see Argvise#initialize
    # @see to_argv_bsd
    #
    # @example Basic usage
    #
    #     require 'argvise'
    #     using Argvise::HashRefin
    #
    #     { v: true, path: '/path/to/dir' }.to_argv
    #     #=> ["-v", "--path", "/path/to/dir"]
    #
    #
    # @example raw_cmd_hash.to_argv is equivalent to:
    #
    #     raw_cmd_hash
    #       .then(&Argvise.new_proc)
    #       .with_bsd_style(false)
    #       .with_kebab_case_flags(true)
    #       .build
    #
    # @return [Array<String>]
    def to_argv(opts = nil)
      Argvise.build(self, opts:)
    end

    # Converts a hash map into BSD-style command-line arguments.
    #
    # @param opts [Hash]
    # @see to_argv
    # @example
    #
    #     require 'argvise'
    #     using Argvise::HashRefin
    #
    #     { path: '/path/to/dir' }.to_argv_bsd
    #     #=> ["-path", "/path/to/dir"]
    #
    # @return [Array<String>]
    def to_argv_bsd(options = {})
      # if options is not Hash Type => {}
      options = {} unless options.is_a?(::Hash)

      opts = options.merge({ bsd_style: true })
      Argvise.build(self, opts:)
    end
  end

  # Converts a hash map into command-line arguments.
  #
  # Monkey Patching:
  #
  # - Hash#to_argv
  # - Hash#to_argv_bsd
  #
  # @example
  #
  #     require 'argvise'
  #
  #     module A
  #       module_function
  #       include Argvise::HashMixin
  #
  #       def demo
  #         puts({ path: '/path/to/dir' }.to_argv)
  #         #=> ["--path", "/path/to/dir"]
  #
  #         puts({ path: '/path/to/dir' }.to_argv_bsd)
  #         #=> ["-path", "/path/to/dir"]
  #       end
  #     end
  #
  #     A.demo
  #     Hash.method_defined?(:to_argv) # => true
  #     {}.respond_to?(:to_argv) #=> true
  module HashMixin
    def self.included(_host)
      ::Hash.include(HashExt)
    end
  end
end
