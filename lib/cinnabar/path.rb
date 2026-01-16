# frozen_string_literal: true

require 'pathname'

module Cinnabar
  # Build a Proc that converts a string value into a {Kernel.Pathname}.
  #
  # This is handy when you want to pass a converter into higher-order APIs
  # (e.g., map/filter pipelines).
  #
  # @param s [String, Pathname] a path (e.g., file/dir)
  # @return [Proc] a lambda that maps `s` to `Pathname(s)`
  #
  # @example convert a list of directories to Pathname objects
  #
  #     conv = Cinnabar.to_path_proc
  #     %w[/tmp /var].map(&conv)
  #     #=> [#<Pathname:/tmp>, #<Pathname:/var>]
  def self.to_path_proc = ->(s) { Pathname(s) }
end

module Cinnabar
  module_function

  def firb_path
    File.expand_path('../../misc/firb/bin/', Kernel.__dir__)
  end

  def firb_installation_script_path
    File.expand_path('../../misc/firb/install.ps1', Kernel.__dir__)
  end
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
