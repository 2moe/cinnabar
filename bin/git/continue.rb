# frozen_string_literal: true

require 'io/console'

def run_cmd_or_cancel = ->(command) do
  print 'Continue? [Y/n] '
  case char = $stdin.getch.downcase
    when 'y' then system command
    else puts char
  end
end
