# frozen_string_literal: true

module Cinnabar; end

module Cinnabar::Utils
  module_function

  # @note require 'rubygems'
  def gems! = Kernel.require 'rubygems'
end

module Cinnabar::Utils::OS
  module_function

  # Returns true if running on Windows (including MSYS/MinGW/Cygwin).
  #
  # @param host_os [String]
  # @return [Boolean]
  #
  # @example
  #   Cinnabar::Utils::OS.windows? #=> true/false
  def windows?(host_os = RUBY_PLATFORM)
    host_os.match?(/bccwin|cygwin|djgpp|mingw|mswin|wince/i)
  end

  # Returns true if running on macOS (Darwin).
  #
  # Ruby convention prefers `macos?` over `macOS?`, but we provide both.
  #
  # @param host_os [String]
  # @return [Boolean]
  #
  # @example
  #   Cinnabar::Utils::OS.macos? #=> true/false
  def macOS?(host_os = RUBY_PLATFORM) # rubocop:disable Naming/MethodName
    host_os.match?(/darwin/i)
  end

  # Returns true if running on Linux.
  #
  # @param host_os [String]
  # @return [Boolean]
  def linux?(host_os = RUBY_PLATFORM)
    host_os.match?(/linux/i)
  end

  # Returns true if running under WSL 2
  #
  # @param proc_version [String]
  # @return [Boolean]
  # @see wsl_1?
  # @see wsl?
  #
  # @example
  #   Cinnabar::Utils::OS.wsl_2? #=> true/false
  def wsl_2?(proc_version = nil)
    proc_version ||= File.read('/proc/version')

    # proc_version.match?(/(?=.*microsoft)(?=.*-WSL)/)
    proc_version.include?('microsoft') && proc_version.include?('-WSL')
  rescue StandardError
    false
  end

  # Returns true if running under WSL (Windows Subsystem for Linux).
  def wsl?(proc_version = nil)
    proc_version ||= File.read('/proc/version')
    proc_version.match?(/(M|m)icrosoft/)
  rescue StandardError
    false
  end

  # Returns true if running under WSL 1
  def wsl_1?(proc_version = nil)
    # wsl 1: Linux version 4.4.0-26100-Microsoft (Microsoft@Microsoft.com) (gcc version 5.4.0 (GCC) ) #7309-Microsoft Fri Jan 01 08:00:00 PST 2016 # rubocop:disable Layout/LineLength
    proc_version ||= File.read('/proc/version')
    proc_version.include?('Microsoft')
  rescue StandardError
    false
  end
end
