# rubocop:disable Style/MixinUsage
# frozen_string_literal: true

require 'fileutils'
FS = FileUtils

# ----------
# To ensure compatibility with "--disable=gems", we must load the `sinlog` first,
# and then we can load `cinnabar`.
require_relative 'misc/download/sinlog'
require_relative 'misc/download/argvise'
require_relative 'lib/cinnabar'

include Cinnabar::FnPipe::Mixin
include Cinnabar::Downloader::StrMixin
include Cinnabar::Command::ArrMixin
include Cinnabar::Command::TaskArrMixin

include Sinlog::Mixin
include Argvise::HashMixin
# ----------
#
load ARGV[0]
