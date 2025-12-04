# frozen_string_literal: true

module Sinlog
  module_function

  # @param level [Integer, String, Symbol, nil] Log Level.
  #
  # @return [Integer] the log level as an integer.
  #
  # @note If `level` is `nil`, returns `Sinlog.logger.level`.
  #
  # @example
  #
  #     require 'sinlog'
  #
  #     # optional values:
  #     #    'debug', 'info', 'warn', 'error', 'fatal', 'unknown',
  #     #    'dbg', 'information', 'warning', 'err', 'unk',
  #     #    '0', '1', '2', '3', '4', '5'
  #
  #     Sinlog.as_log_level(:dbg) #=> LV[:debug] => 0
  #     Sinlog.as_log_level('info') #=> LV[:info] => 1
  def as_log_level(level = nil) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
    level = Sinlog.logger.level if level.nil?
    case level
      when 0..5
        level
      when '0', '1', '2', '3', '4', '5'
        level.to_i
      when 'debug', 'dbg', :dbg
        LV[:debug]
      when 'info', 'information'
        LV[:info]
      when 'warn', 'warning'
        LV[:warn]
      when 'err', 'error', :err
        LV[:error]
      when 'fatal'
        LV[:fatal]
      when 'unk', 'unknown', :unk
        LV[:unknown]
      when Symbol
        LV.fetch(level, LV[:error])
      else
        LV[:error]
    end
  end

  # @return [<Sinlog::Logger>] `=> Sinlog::Logger.instance`
  def instance
    Sinlog::Logger.instance
  end

  # Configures and returns the `Sinlog.instance.logger`.
  #
  # @param level [Integer, String, Symbol, nil]  Log Level.
  # @param env_name [#to_s]  Name of the environment variable.
  # @return [StdLogger]
  #
  # ## English
  #
  #
  # You can configure the log level through parameters.
  #
  # - env_name
  #   - Specifies the name of an environment variable.
  #   - If set to nil, the program will attempt to read `RUBY_LOG` and set the log level accordingly.
  #     - Example: logger(env_name: nil)
  #       - If the user runs `RUBY_LOG=debug ./[your-script].rb`
  #       - The log level will be set to `debug`.
  #     - Example: logger(env_name: "XX_CLI_LOG")
  #       - If the user runs `XX_CLI_LOG=warn ./[your-script].rb`
  #       - The log level will be set to `warn`.
  #
  # - level
  #   - The level parameter takes precedence over env_name.
  #     - If both level and env_name are provided, the program will parse level first and return early.
  #
  # ## 中文
  #
  # 配置并获取 `Sinlog.instance.logger`。
  #
  # 我们可以通过参数来配置日志级别。
  #
  # - env_name
  #   - 指定特定的环境变量名称
  #   - 当其为 nil 时，程序默认会尝试获取 RUBY_LOG 的值，并设置日志级别。
  #     - 假设 logger(env_name: nil)
  #       - 若用户调用 `RUBY_LOG=debug ./[your-script].rb`
  #       - 则日志级别为 debug
  #     - 假设 logger(env_name: "XX_CLI_LOG")
  #       - 若用户调用 `XX_CLI_LOG=warn ./[your-script].rb`
  #       - 则日志级别为 warn
  # - level
  #   - level 的优先级要高于 env_name
  #     - 若 level 和 env_name 都不为 nil, 则程序会优先解析 level，并提前 return。
  #
  # @see Sinlog::Logger.logger
  #
  # @example
  #
  #     require 'sinlog'
  #
  #     # optional level values:
  #     #   - "debug"
  #     #   - "dbg"
  #     #   - "info"
  #     #   - "warn"
  #     #   - "error"
  #     #   - "err"
  #     #   - "fatal"
  #     #   - "unknown"
  #     #   - "unk"
  #     #   - Integer (e.g., Sinlog::LV[:debug])
  #
  #     log = Sinlog.logger(level: "dbg")
  #     log.level == Sinlog::LV[:debug]  #=> true
  #     a = "Foo"
  #     log.debug "a=#{a}"
  #
  #     using Sinlog::Refin
  #     Sinlog.logger(level: 'warn')
  #     log.level == Sinlog::LV[:warn]  #=> true
  #     "Bar".log_warn
  #
  #     ENV["CUSTOM_LOG"] = 'info'
  #     log = Sinlog.logger(env_name: "CUSTOM_LOG")
  #     log.level == Sinlog::LV[:info]  #=> true
  #     "Baz".log_info
  #
  #     log = Sinlog.logger(level: "error", env_name: "CUSTOM_LOG")
  #     log.level == Sinlog::LV[:error]  #=> true
  #     "foobar".log_err
  #
  def logger(level: nil, env_name: nil)
    std_logger = instance.logger

    # if level != nil
    return std_logger.tap { _1.level = as_log_level(level) } unless level.nil?

    # if env_name != nil
    instance.set_level_from_env!(env_name) unless env_name.nil?

    std_logger
  end
end
