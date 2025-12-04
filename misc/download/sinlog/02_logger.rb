# frozen_string_literal: true

module Sinlog # rubocop:disable Style/ClassAndModuleChildren
  # Logger Singleton Class
  class Logger
    require 'singleton'

    include Singleton
    attr_reader :logger

    # Since this is a Singleton class, you should use {.instance} instead of `.new`.
    #
    # @return [self] Sinlog::Logger
    #
    # @example
    #
    #     instance = Sinlog::Logger.instance
    #     instance.logger.info "Hello"
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

    # Configures and returns the {StdLogger}.
    #
    # @note  Similar to {Sinlog.logger}, but uses different parameter types.
    #
    #  - {Sinlog.logger}: uses keyword arguments, e.g., (level: "info", env_name: "RUBY_LOG")
    #  - This function: uses positional arguments, e.g., ("warn", "CUSTOM_LOG")
    #
    # @param level [Integer, String, Symbol, nil]  Log Level.
    # @param env_name [#to_s]  Name of the environment variable.
    #
    # @return [StdLogger]
    #
    # @see Sinlog.logger
    #
    # ## Example
    #
    #     log = Sinlog::Logger.logger("debug")
    #     log.info "Information"
    #     log.debug "This is a debug message"
    #
    # The log output format will be similar to:
    #
    # <ul>
    #   <li><p><span style="color:darkcyan;">[INFO]</span> 21:29:22.004 Information</p></li>
    #   <li><p><span style="color:blue;">[DEBUG]</span> 21:29:22.005 This is a debug message</p></li>
    # </ul>
    #
    # > Where "INFO" is highlighted in cyan and "DEBUG" is highlighted in blue.
    #
    # The default log level is set based on the `RUBY_LOG` environment variable.
    #
    # If this variable is not set, the default level is `DEBUG`.
    def self.logger(level = nil, env_name = nil)
      Sinlog.logger(level:, env_name:)
    end

    # Sets the `@logger.level` (**log level**) based on the value of an environment variable.
    #
    # If `env_name` is not specified, it reads the value of the `RUBY_LOG` environment variable.
    #
    # - If the value exists, it is converted to lowercase, then to a symbol, and looked up in the LV hash;
    # - If it does not exist, the default level is `DEBUG(0)`;
    # - If the lookup result is invalid, the level is set to `ERROR(3)`;
    # - If the environment variable value is empty, the lookup result will be invalid,
    #   and the level will be set to `ERROR(3)`.
    #
    # @example
    #
    #     ENV["XX_LOG"] = "info" # or setenv in posix-sh: export XX_LOG=info
    #
    #     level = Sinlog.instance.set_level_from_env!("XX_LOG")
    #     level == Sinlog::LV[:info] # => true
    #
    #     log = Sinlog.logger
    #     log.debug "This message will not be displayed because the current log level is info"
    #     log.info "Hello!"
    #
    # @return [Integer] `@logger.level`
    # @param env_name [#to_s] Name of the environment variable.
    def set_level_from_env!(env_name = 'RUBY_LOG')
      env_str = ENV[env_name.to_s]&.downcase || 'debug'

      Sinlog
        .as_log_level(env_str)
        .tap { @logger.level = _1 }
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
