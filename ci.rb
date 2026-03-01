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
  CI_DIR = -> {
    enval = ENV['CINNABAR_CI_DIR']
    case enval
      when nil, ''
        ()
      else
        return File.expand_path(enval, __dir__)
    end

    %w[.github/_ci_ misc/ci]
      .map { File.expand_path("../#{_1}", __dir__) }
      .find { |path| Dir.exist?(path) } || File.expand_path('ci', __dir__)
  }.call

  CI_LIBS = -> {
    case enval = ENV['CINNABAR_CI_LIBS']
      when nil, ''
        return ()
    end

    data = JSON.parse(enval)
    case data
      when []
        ()
      when Array
        data
      else
        ()
    end
  }.call
end

if Dir.exist? Cinnabar::CI_DIR
  def require_ci(script) = require File.join(Cinnabar::CI_DIR, script)

  Cinnabar::CI_LIBS&.each { require_ci(_1) }
end

# ----------
load ARGV[0]
