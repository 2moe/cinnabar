# frozen_string_literal: true

module Sinlog
  module_function

  # => Integer
  #
  # == Example
  #
  #     require 'sinlog'
  #
  #     # values: 'debug', 'info', 'warn', 'error', 'fatal', 'unknown'
  #     Sinlog.to_log_level('dbg') #=> LV[:debug] => 0
  #     Sinlog.to_log_level('info') #=> LV[:info] => 1
  #
  def to_log_level(level) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
    case level
      when 0..5
        level
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

  # => Sinlog::Logger.instance
  def instance
    Sinlog::Logger.instance
  end

  # => ::Logger
  #
  # == English
  #
  # Creates a new ::Logger instance.
  #
  # You can configure the log level through parameters.
  #
  # - env_name
  #   - Type: String
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
  #   - Type: Integer OR String OR Symbol
  #   - The level parameter takes precedence over env_name.
  #     - If both level and env_name are provided, the program will parse level first and return early.
  #
  # == 中文
  #
  # 创建一个新的 ::Logger 实例。
  #
  # 我们可以通过参数来配置日志级别。
  #
  # - env_name
  #   - 类型: String
  #   - 指定特定的环境变量名称
  #   - 当其为 nil 时，程序默认会尝试获取 RUBY_LOG 的值，并设置日志级别。
  #     - 假设 logger(env_name: nil)
  #       - 若用户调用 `RUBY_LOG=debug ./[your-script].rb`
  #       - 则日志级别为 debug。
  #     - 假设 logger(env_name: "XX_CLI_LOG")
  #       - 若用户调用 `XX_CLI_LOG=warn ./[your-script].rb`
  #       - 则日志级别为 warn。
  # - level
  #   - 类型: Integer OR String OR Symbol
  #   - level 的优先级要高于 env_name
  #     - 若 level 和 env_name 都不为 nil, 则程序会优先解析 level，并提前 return。
  #
  # == Example
  #
  #     require 'sinlog'
  #
  #     # level values:
  #     #   - "debug"
  #     #   - "dbg"
  #     #   - "info"
  #     #   - "warn"
  #     #   - "error"
  #     #   - "err"
  #     #   - "fatal"
  #     #   - Integer (e.g., Sinlog::LV[:debug])
  #
  #     log = Sinlog.logger(level: "dbg")
  #     log.level == Sinlog::LV[:debug]  #=> true
  #     a = 3
  #     log.debug "a=#{a}"
  #
  #     log = Sinlog.logger(level: 'warn')
  #     log.level == Sinlog::LV[:warn]  #=> true
  #     log.error "Failed to open file."
  #
  #     ENV["CUSTOM_LOG"] = 'info'
  #     log = Sinlog.logger(env_name: "CUSTOM_LOG")
  #     log.level == Sinlog::LV[:info]  #=> true
  #
  #     log = Sinlog.logger(env_name: "CUSTOM_LOG", level: "error")
  #     log.level == Sinlog::LV[:error]  #=> true
  #
  def logger(env_name: nil, level: nil)
    std_logger = instance.logger

    # if level != nil
    return std_logger.tap { _1.level = to_log_level(level) } unless level.nil?

    # if env_name != nil
    instance.set_level_from_env!(env_name) unless env_name.nil?

    std_logger
  end
end
