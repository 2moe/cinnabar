# rubocop:disable Style/MixinUsage
# frozen_string_literal: true

require 'fileutils'
FS = FileUtils

# `load_path`.push 'misc/download'
$: << File.expand_path('misc/download', __dir__)

# Fix ruby v4.0:
#   When `--disable=gems` is used, the `$LOAD_PATH` for `logger` must be specified manually,
#   otherwise `sinlog` will raise an error.
-> {
  return if RUBY_VERSION.split('.').first.to_i <= 3

  require_relative 'lib/cinnabar/gem_path'

  {
    cache_file: File.expand_path('load_path.json', __dir__),
    gems: %w[logger],
  }.then(&Cinnabar.new_gem_path_proc)
    .append_load_path!
}.call

# ----------
require 'argvise'
require 'sinlog'

require_relative 'lib/cinnabar'

include Cinnabar::FnPipe::Mixin
include Cinnabar::Downloader::StrMixin
include Cinnabar::Command::ArrMixin
include Cinnabar::Command::TaskArrMixin
include Cinnabar::StrToPath::Mixin

include Sinlog::Mixin
include Argvise::HashMixin
# ----------
module Cinnabar
  CI_DIR = %w[.github/_ci_ misc/ci]
    .map { File.expand_path("../#{_1}", __dir__) }
    .find { |path| Dir.exist?(path) } || File.expand_path('ci', __dir__)
end

if Dir.exist? Cinnabar::CI_DIR
  def require_ci(script) = require File.join(Cinnabar::CI_DIR, script)
end

# ----------
load ARGV[0]
