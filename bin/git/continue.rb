# frozen_string_literal: true

require 'io/console'

def continue_or_cancel?
  print 'Continue? [Y/n] '
  case char = $stdin.getch.downcase
    when 'y'
      return true
  end

  puts char
  false
end
