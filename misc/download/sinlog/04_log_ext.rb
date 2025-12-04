# frozen_string_literal: true

module Sinlog
  # @private
  #
  # == Methods
  #
  # - `#log_dbg`   – DEBUG
  # - `#log_info`  – INFO
  # - `#log_warn`  – WARN
  # - `#log_err`   – ERROR
  # - `#log_fatal` – FATAL
  # - `#log_unk`   – UNKNOWN
  module LogExt
    def log_dbg
      Sinlog.logger.debug(self)
    end

    def log_info
      Sinlog.logger.info(self)
    end

    def log_warn
      Sinlog.logger.warn(self)
    end

    def log_err
      Sinlog.logger.error(self)
    end

    def log_fatal
      Sinlog.logger.fatal(self)
    end

    def log_unk
      Sinlog.logger.unknown(self)
    end
  end
  # -----
  private_constant :LogExt
end
