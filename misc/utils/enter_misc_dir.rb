# frozen_string_literal: true

require 'pathname'

Pathname(__dir__.to_s)
  .parent
  .then { Dir.chdir _1 }
