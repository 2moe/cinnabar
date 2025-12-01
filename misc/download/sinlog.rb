# frozen_string_literal: true

# == Logging Modules Overview
#
# The following modules provide different ways to add logging capabilities:
#
# * Refin        : A refinement. Activate it with `using` to add logging methods with the `log_` prefix.
# * ShortRefin   : A refinement. Similar to `Sinlog::Refin`, but methods omit the `log_` prefix.
# * Mixin        : A mixin module. It's a global object monkey patch, use `include Sinlog::Mixin` with caution.
# * ShortMixin   : A mixin module. Similar to `Sinlog::Mixin`, but methods omit the `log_` prefix.
#
# === Comparison Table (Monkey Patching)
#
# | Module     | Type       | Activation | Method Naming                                            |
# | ---------- | ---------- | ---------- | -------------------------------------------------------- |
# | Mixin      | Mixin      | include    | log_dbg, log_info, log_warn, log_err, log_fatal, log_unk |
# | Refin      | Refinement | using      | log_dbg, log_info, log_warn, log_err, log_fatal, log_unk |
# | ShortMixin | Mixin      | include    | dbg, info, warn, err, fatal, unk                         |
# | ShortRefin | Refinement | using      | dbg, info, warn, err, fatal, unk                         |
#
# == Examples
#
# === Classic (neither mixin nor refinement)
#
#     require 'sinlog'
#
#     log = Sinlog.logger
#     log.info "Information"
#     log.debug "This is a debug message"
#
# === Mixin
#
#     require 'sinlog'
#     include Sinlog::Mixin
#
#     "Hello".log_info
#     "World".log_dbg
#
# === Refinement
#
#     require 'sinlog'
#
#     using Sinlog::Refin
#     "Foo".log_info
#
#     using Sinlog::ShortRefin
#     "Bar".warn
#
# Read more: https://github.com/2moe/sinlog-gem
module Sinlog; end

require_relative 'sinlog/version'

require_relative 'sinlog/consts'
require_relative 'sinlog/logger'
require_relative 'sinlog/module_fn'

require_relative 'sinlog/log_ext'
require_relative 'sinlog/short_ext'

require_relative 'sinlog/loggable'
