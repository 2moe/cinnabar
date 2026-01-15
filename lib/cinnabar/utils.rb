module Cinnabar::Utils
  module_function

  def windows?
    RUBY_PLATFORM.match?(/bccwin|cygwin|djgpp|mingw|mswin|wince/i)
  end

  def macOS?
    RUBY_PLATFORM.match?(/darwin/i)
  end

  def linux?
    RUBY_PLATFORM.match?(/linux/i)
  end

  def gems = Kernel.require 'rubygems'
end
