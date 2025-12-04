# frozen_string_literal: true

# Provides a set of reusable **unary lambdas**.
#
# @note  Each function is implemented using `Kernel.lambda(&:log_xxx)`
#
# @example
#
#     Log = Sinlog::Proc
#     'debug'.tap &Log.dbg
#     'information'.tap &Log.info
#     'warning'.tap &Log.warn
#     'error'.tap &Log.err
#     'fatal'.tap &Log.fatal
#     'unknown'.tap &Log.unk
#
module Sinlog::Proc
  module_function

  # + Object#log_*
  using Sinlog::Refin

  # Returns a lambda that calls `log_dbg` on the given object.
  #
  # @return [::Proc] `.call(Object)` => Boolean
  #
  # @example Basic usage
  #
  #   Log = Sinlog::Proc
  #
  #   "debug message".tap &Log.dbg
  #   # OR: Log.dbg["debug message"]
  #   # OR: Log.dbg.call("debug message")
  #
  def dbg
    Kernel.lambda(&:log_dbg)
  end

  # Returns a lambda that calls `log_info` on the given object.
  #
  # @return [::Proc] `.call(Object)` => Boolean
  #
  # @example
  #
  #     "info message".tap &Sinlog::Proc.info
  def info
    Kernel.lambda(&:log_info)
  end

  # Returns a lambda that calls `log_warn` on the given object.
  #
  # @return [::Proc] `.call(Object)` => Boolean
  #
  # @example
  #
  #     "warning message".tap &Sinlog::Proc.warn
  def warn
    Kernel.lambda(&:log_warn)
  end

  # Returns a lambda that calls `log_err` on the given object.
  #
  # @return [::Proc] `.call(Object)` => Boolean
  #
  # @example
  #
  #     "Error message".tap &Sinlog::Proc.err
  def err
    Kernel.lambda(&:log_err)
  end

  # Returns a lambda that calls `log_fatal` on the given object.
  #
  # @return [::Proc] `.call(Object)` => Boolean
  #
  # @example
  #
  #     "Fatal Error message".tap &Sinlog::Proc.fatal
  def fatal
    Kernel.lambda(&:log_fatal)
  end

  # Returns a lambda that calls `log_unk` on the given object.
  #
  # @return [::Proc] `.call(Object)` => Boolean
  #
  # @example
  #
  #     "Unknown Level".tap &Sinlog::Proc.unk
  def unk
    Kernel.lambda(&:log_unk)
  end
end
