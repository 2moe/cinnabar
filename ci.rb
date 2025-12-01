# rubocop:disable Style/MixinUsage
# frozen_string_literal: true

require 'fileutils'
FS = FileUtils

require 'json'

# ----------
# To ensure compatibility with "--disable=gems", we must load the `sinlog` first,
# and then we can load `cinnabar`.
require_relative 'misc/download/sinlog'
require_relative 'misc/download/argvise'

require_relative 'lib/cinnabar'

# TODO: Use environment variables to control require and include behavior

include Cinnabar::FnPipe::Mixin
include Cinnabar::Command::ArrMixin
include Cinnabar::Downloader::StrMixin

include Sinlog::Mixin
include Argvise::HashMixin
# ----------
#
load ARGV[0]
