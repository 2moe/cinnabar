# frozen_string_literal: true

# Define Cinnabar first to prevent errors when creating Cinnabar::SubMod
# (compact ClassAndModuleChildren)
#
# ------------------

module Cinnabar; end

# To ensure compatibility with "--disable=gems" (allowing users to pre-require),
# add conditional checks before requiring these libraries.
require 'sinlog' unless defined? Sinlog::VERSION
# require 'argvise' unless defined? Argvise::VERSION

require 'pathname'
