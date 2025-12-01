# frozen_string_literal: true

module Sinlog
  # == Overview
  #
  # * `log_dbg`   – DEBUG
  # * `log_info`  – INFO
  # * `log_warn`  – WARN
  # * `log_err`   – ERROR
  # * `log_fatal` – FATAL
  # * `log_unk`   – UNKNOWN
  #
  module LogExt
    # Logs the current object at *debug* level using Sinlog.logger
    def log_dbg
      Sinlog.logger.debug(self)
    end

    # Logs the current object at *information* level using Sinlog.logger
    def log_info
      Sinlog.logger.info(self)
    end

    # Logs the current object at *warning* level using Sinlog.logger
    def log_warn
      Sinlog.logger.warn(self)
    end

    # Logs the current object at *error* level using Sinlog.logger
    def log_err
      Sinlog.logger.error(self)
    end

    # Logs the current object at *fatal* level using Sinlog.logger
    def log_fatal
      Sinlog.logger.fatal(self)
    end

    # Logs the current object at *unknown* level using Sinlog.logger
    def log_unk
      Sinlog.logger.unknown(self)
    end
  end
  # -----
  private_constant :LogExt
end
