# rubocop:disable Layout/LineLength
# rubocop:disable Style/SpecialGlobalVars
#
# frozen_string_literal: true

def capture_stdout(command)
  out = IO.popen(command, 'r', &:read)
  return nil unless $?.success?

  out
rescue Errno::ENOENT
  nil
end

# @example Linux
#
#     which 'ls'
#        # => ["/usr/bin/ls"]
#     which :ruby
#       # => ["/opt/ruby/latest/bin/ruby"]
#
# @example Windows
#
#     which :cl
#     # => ["C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.50.35717\\bin\\Hostx64\\x64\\cl.exe"]
def which(cmd) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
  cmd = cmd.to_s if cmd.is_a? Symbol
  return warn 'Try: show_source your_cmd' unless cmd.is_a?(String)

  probes =
    if Cinnabar::Utils::OS.windows?
      %w[where which command]
    else
      %w[which command where]
    end

  strip_cmds = ->(out) {
    out
      .to_s
      .lines
      .map(&:strip)
      .reject(&:empty?)
  }

  probes.each do |probe|
    out =
      case probe
        when 'command'
          capture_stdout %w[sh -c].push("command -v #{cmd}")
        else
          capture_stdout [probe, cmd]
      end
    next if out.nil? || out.empty?

    cmds = strip_cmds[out]
    return cmds unless cmds.empty?
  end

  nil
end
