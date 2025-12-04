# typed: true
# frozen_string_literal: true

# To maintain `mruby` compatibility, define `private_constant` and
#  `refinements` in **refinement.rb** rather than in **core.rb**.

class Argvise # rubocop:disable Style/ClassAndModuleChildren
  # Probably no need to mark this as private.
  # private_constant :HashExt

  # Refinements:
  #
  # - Hash#to_argv
  # - Hash#to_argv_bsd
  #
  # @example
  #
  #     require 'argvise'
  #     class A
  #       using Argvise::HashRefin
  #       def self.demo
  #         puts({ target: "wasm32-wasip2" }.to_argv)
  #           # => ["--target", "wasm32-wasip2"]
  #
  #         puts({ target: "wasm32-wasip2" }.to_argv_bsd)
  #           # => ["-target", "wasm32-wasip2"]
  #
  #         puts({}.respond_to?(:to_argv)) #=> true
  #       end
  #     end
  #
  #     A.demo
  #     Hash.method_defined?(:to_argv) # => false
  #     {}.respond_to?(:to_argv) #=> false
  #
  module HashRefin
    refine ::Hash do
      import_methods HashExt
    end
  end
end
