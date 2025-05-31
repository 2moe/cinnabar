require 'pathname'

Pathname(__dir__ || File.dirname(__FILE__))
  .parent
  .then { Dir.chdir(it) }
