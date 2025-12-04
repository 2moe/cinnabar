# frozen_string_literal: true

require 'pathname'

# File.expand_path('..', __dir__).tap { Dir.chdir _1 }
Pathname(__dir__.to_s)
  .parent
  .then { Dir.chdir(_1) }
