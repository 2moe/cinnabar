# frozen_string_literal: true

module Sinlog
  # Provides logging helpers for any object.
  #
  # == Overview
  #
  # * `log_dbg`   – DEBUG
  # * `log_info`  – INFO
  # * `log_warn`  – WARN
  # * `log_err`   – ERROR
  # * `log_fatal` – FATAL
  # * `log_unk`   – UNKNOWN
  #
  # == Example
  #
  #     require 'sinlog'
  #
  #     include Sinlog::Mixin
  #
  #     "A debug message".log_dbg
  #     "Hello, world".log_info
  #
  #     Object.method_defined?(:log_warn) #=> true
  #
  module Mixin
    def self.included(_host)
      ::Object.include(LogExt)
    end
  end

  # Provides logging helpers for any object.
  #
  # - The main difference from `Sinlog::Mixin` is that `Refin` uses Refinements instead of Mixins.
  #   - You need to activate it with `using Sinlog::Refin`
  #   - rather than `include Sinlog::Mixin`.
  #
  # == Source
  #
  #     refine ::Object { import_methods LogExt }
  #
  # == Overview
  #
  # * `log_dbg`   – DEBUG
  # * `log_info`  – INFO
  # * `log_warn`  – WARN
  # * `log_err`   – ERROR
  # * `log_fatal` – FATAL
  # * `log_unk`   – UNKNOWN
  #
  # == Example
  #
  #     require 'sinlog'
  #
  #     module A
  #       module_function
  #       using Sinlog::Refin
  #
  #       def demo = "Something happened".log_warn
  #       def respon_to_log_dbg? = [].respond_to? :log_dbg
  #     end
  #
  #     A.demo
  #       # => [WARN] 11:17:38.024 Something happened
  #       # => (WARN is displayed in yellow highlight; 11:17:38.024 is the current time and may vary)
  #
  #     A.respon_to_log_dbg?  # => true
  #     [].respond_to? :log_dbg #=> false
  #
  module Refin
    refine ::Object do
      import_methods LogExt
    end
  end

  # Provids convenient logging methods.
  #
  # Similar to `Sinlog::Refin`, but methods omit the `log_` prefix.
  #
  # For example:
  #   * `"msg".err` instead of `"msg".log_err`;
  #   * `"msg".warn` instead of `"msg".log_warn`
  #
  # == Source
  #
  #     refine ::Object { import_methods LogShortExt }
  #
  # == Overview
  #
  # * `dbg`   – DEBUG
  # * `info`  – INFO
  # * `warn`  – WARN
  # * `err`   – ERROR
  # * `fatal` – FATAL
  # * `unk`   – UNKNOWN
  #
  # == Example
  #
  #     require 'sinlog'
  #
  #     module A
  #       module_function
  #       using Sinlog::ShortRefin
  #
  #       def demo = "Something happened".warn
  #       def respon_to_dbg? = [].respond_to? :dbg
  #     end
  #
  #     A.demo
  #       # => [WARN] 11:17:38.024 Something happened
  #       # => (WARN is displayed in yellow highlight; 11:17:38.024 is the current time and may vary)
  #
  #     A.respon_to_dbg?  # => true
  #     [].respond_to? :dbg #=> false
  #
  module ShortRefin
    refine ::Object do
      import_methods LogShortExt
    end
  end

  # Provids convenient logging methods.
  #
  # Similar to `Sinlog::Mixin`, but methods omit the `log_` prefix.
  #
  # Note: Since mixin monkey patching pollutes the global scope, use `include Sinlog::ShortMixin` with caution.
  #
  # == Overview
  #
  # * `dbg`   – DEBUG
  # * `info`  – INFO
  # * `warn`  – WARN
  # * `err`   – ERROR
  # * `fatal` – FATAL
  # * `unk`   – UNKNOWN
  #
  # == Example
  #
  #     require 'sinlog'
  #
  #     include Sinlog::ShortMixin
  #
  #     "A debug message".dbg
  #     "Hello, world".info
  #
  #     Object.method_defined?(:err) #=> true
  #
  module ShortMixin
    def self.included(_host)
      ::Object.include(LogShortExt)
    end
  end
end
