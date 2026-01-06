# frozen_string_literal: true

require 'pathname'

# File.expand_path('..', __dir__).tap { Dir.chdir _1 }
Pathname(__dir__ || '.')
  .parent
  .then { Dir.chdir(_1) }
