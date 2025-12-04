# frozen_string_literal: true

# Provides a set of reusable **unary functions** that call logging methods.
#
# - `dbg`   – DEBUG
# - `info`  – INFO
# - `warn`  – WARN
# - `err`   – ERROR
# - `fatal` – FATAL
# - `unk`   – UNKNOWN
#
# -------------
#
# @example
#
#     Sinlog.dbg 'debug'
#     Sinlog.info 'information'
#     Sinlog.warn 'warning'
#     Sinlog.err 'error'
#     Sinlog.fatal 'fatal'
#     Sinlog.unk 'unknown'
#
module Sinlog
  module_function

  # + Object#log_*
  using Sinlog::Refin

  # @param obj [Object]
  # @return [Boolean]
  #
  # @example Basic usage
  #
  #   Sinlog.dbg "This is a debug message"
  #
  def dbg(obj)
    obj.log_dbg
  end

  # @param obj [Object]
  # @return [Boolean]
  #
  # @example
  #
  #     Sinlog.info "info message"
  def info(obj)
    obj.log_info
  end

  # @param obj [Object]
  # @return [Boolean]
  #
  # @example
  #
  #     Sinlog.warn "warning message"
  def warn(obj)
    obj.log_warn
  end

  # @param obj [Object]
  # @return [Boolean]
  #
  # @example
  #
  #     Sinlog.err "Error message"
  def err(obj)
    obj.log_err
  end

  # @param obj [Object]
  # @return [Boolean]
  #
  # @example
  #
  #     Sinlog.fatal "Fatal Error message"
  def fatal(obj)
    obj.log_fatal
  end

  # @param obj [Object]
  # @return [Boolean]
  #
  # @example
  #
  #     Sinlog.unk "Unknown Level"
  def unk(obj)
    obj.log_unk
  end
end
