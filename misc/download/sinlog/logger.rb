# frozen_string_literal: true

# Logger Singleton Class
module Sinlog
  class Logger
    require 'singleton'

    include Singleton
    attr_reader :logger

    # Example:
    #
    #     logger = Sinlog::Logger.instance.logger
    #     logger.info "Information"
    #     logger.debug "This is a debug message"
    #
    # The log output format will be similar to:
    #
    #   [INFO] 21:29:22.004  Information
    #   [DEBUG] 21:29:22.005  This is a debug message
    #
    # Where "INFO" is highlighted in cyan and "DEBUG" is highlighted in blue.
    #
    # The default log level is set based on the RUBY_LOG environment variable.
    # If this variable is not set, the default level is DEBUG.
    def initialize
      @logger = StdLogger.new($stderr)
      set_level_from_env!
      @logger.formatter = Kernel.proc do |severity, datetime, progname, msg|
        color = COLORS[severity.downcase.to_sym]
        reset = COLORS[:unknown]
        formatted_datetime = datetime.strftime('%H:%M:%S.%L')
        prog = format_prog_name(progname)
        "[#{color}#{severity}#{reset}] #{formatted_datetime} #{prog}#{msg}\n"
      end
    end

    def self.logger
      instance.logger
    end

    # Set the `@logger.level` (**log level**) based on the value of an environment variable.
    #
    # If env_name is not specified, it reads the value of the `RUBY_LOG` environment variable.
    #
    # - If the value exists, it is converted to lowercase, then to a symbol, and looked up in the LV hash;
    # - If it does not exist, the default level is DEBUG(0);
    # - If the lookup result is invalid, the level is set to ERROR(3);
    # - If the environment variable value is empty, the lookup result will be invalid,
    #   and the level will be set to ERROR(3).
    #
    # Example:
    #
    #     ENV["XX_LOG"] = "info" # or setenv in posix-sh: export XX_LOG=info
    #     logger = Sinlog::Logger.instance.tap { it.set_level_from_env!("XX_LOG") }.logger
    #
    #     logger.debug "This message will not be displayed because the current log level is info"
    #     logger.info "Hello!"
    def set_level_from_env!(env_name = 'RUBY_LOG')
      env_str = ENV[env_name]&.downcase || 'debug'

      Sinlog
        .to_log_level(env_str)
        .then { @logger.level = _1 }
    end

    private

    def format_prog_name(progname)
      return '' if progname.to_s.empty?

      green = "\e[32m"
      reset = "\e[0m"
      space = ' '
      "<#{green}#{progname}#{reset}>#{space}"
    end
  end
end
