# frozen_string_literal: true

require 'logger'

module Sinlog
  StdLogger = ::Logger

  # Define colors for different log levels
  COLORS = {
    debug: "\e[34m",   # Blue
    info: "\e[36m",    # Cyan
    warn: "\e[33m",    # Yellow
    error: "\e[31m",   # Red
    fatal: "\e[35m",   # Magenta
    unknown: "\e[0m", # Reset
  }.freeze

  # log levels
  LV = {
    debug: StdLogger::DEBUG,
    info: StdLogger::INFO,
    warn: StdLogger::WARN,
    error: StdLogger::ERROR,
    fatal: StdLogger::FATAL,
    unknown: StdLogger::UNKNOWN,
  }.freeze
end
