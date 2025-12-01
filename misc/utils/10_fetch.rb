#!/usr/bin/env ruby
# typed: false
# frozen_string_literal: true

# ----------------
require_relative 'enter_misc_dir'

require 'pathname'
require 'fileutils'
FS = FileUtils

def get_gem_dir(proj)
  require 'rubygems'

  Gem::Specification
    .find_by_name(proj)
    .gem_dir
    .then { Pathname _1 }
end

# => String  (dir)
#
#  > This fn did this:
#     mkdir_p dir; rm_r proj
#
def init_dir(proj, dir = 'download')
  FS.mkdir_p dir
  Dir.chdir(dir) do
    p "rm -r #{proj}"
    FS.rm_r proj if Dir.exist? proj
  end
  dir
end

def copy_gem_lib_dir
  ->(proj) do
    system "gem install #{proj}"
    dir = init_dir(proj)

    get_gem_dir(proj)
      .join('lib')
      .then { Dir["#{_1}/*"] }
      .tap { p _1 }
      .each { FS.cp_r(_1, dir) }
  end
end

[ # rubocop:disable Style/WordArray
  'argvise',
  'sinlog',
].each(&copy_gem_lib_dir)
