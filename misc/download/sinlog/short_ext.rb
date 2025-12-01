# frozen_string_literal: true

module Sinlog
  # LogShortExt is a module that adds convenient logging methods.
  #
  # Similar to LogExt, but methods omit the `log_` prefix.
  #
  # For example:
  #   * `"msg".err` instead of `"msg".log_err`;
  #   * `"msg".warn` instead of `"msg".log_warn`
  #
  # We can activate it with `using Sinlog::ShortRefin`
  #
  # == Overview
  #
  # * `dbg`   – DEBUG
  # * `info`  – INFO
  # * `warn`  – WARN
  # * `err`   – ERROR
  # * `fatal` – FATAL
  # * `unk`   – UNKNOWN
  module LogShortExt
    # Logs the current object at *debug* level using Sinlog.logger
    def dbg
      Sinlog.logger.debug(self)
    end

    # Logs the current object at *information* level using Sinlog.logger
    def info
      Sinlog.logger.info(self)
    end

    # Logs the current object at *warning* level using Sinlog.logger
    def warn
      Sinlog.logger.warn(self)
    end

    # Logs the current object at *error* level using Sinlog.logger
    def err
      Sinlog.logger.error(self)
    end

    # Logs the current object at *fatal* level using Sinlog.logger
    def fatal
      Sinlog.logger.fatal(self)
    end

    # Logs the current object at *unknown* level using Sinlog.logger
    def unk
      Sinlog.logger.unknown(self)
    end
    # -----
  end
  private_constant :LogShortExt
end
