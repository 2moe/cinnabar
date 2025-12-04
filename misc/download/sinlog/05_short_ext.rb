# frozen_string_literal: true

module Sinlog
  # @private
  #
  # LogShortExt is a module that adds convenient logging methods.
  #
  # Similar to LogExt, but methods omit the `log_` prefix.
  #
  # For example:
  #   - `"msg".err` instead of `"msg".log_err`
  #   - `"msg".warn` instead of `"msg".log_warn`
  #
  # We can activate it with `using Sinlog::ShortRefin`
  #
  #
  # == Methods
  #
  # - `#dbg`   – DEBUG
  # - `#info`  – INFO
  # - `#warn`  – WARN
  # - `#err`   – ERROR
  # - `#fatal` – FATAL
  # - `#unk`   – UNKNOWN
  module LogShortExt
    def dbg
      Sinlog.logger.debug(self)
    end

    def info
      Sinlog.logger.info(self)
    end

    def warn
      Sinlog.logger.warn(self)
    end

    def err
      Sinlog.logger.error(self)
    end

    def fatal
      Sinlog.logger.fatal(self)
    end

    def unk
      Sinlog.logger.unknown(self)
    end
    # -----
  end
  private_constant :LogShortExt
end
