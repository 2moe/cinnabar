#!/usr/bin/env pwsh
# Usage:
#   UNIX:
#     sh install-cinnabar.ps1
#   Windows: Copy everything in this file and paste it into PowerShell to run.
#
# Description: install cinnabar and copy to cache dir
# Note: Although the shebang is `pwsh`, you can run it with POSIX sh.
# Depens: ruby (>= 3.1)

gem install cinnabar

ruby -r pathname -r cinnabar -r fileutils -e "
  gem = 'cinnabar'
  env_dir = ENV['xdg_cache_home'.upcase]
  cache_dir =
    case env_dir
      when nil, ''
        Pathname(Dir.home).join('.cache')
      else Pathname(env_dir)
    end
      .join('ruby')
      .tap(&:mkpath)

  copy_to_cache_dir = ->src { FileUtils.cp_r src, cache_dir, verbose: true }

  lib_dir = Cinnabar::GemPathCore
    .find_lib_paths(gem)
    .first

  firb = File.expand_path('../misc/firb', lib_dir)

  [lib_dir, firb]
    .each(&copy_to_cache_dir)
"
