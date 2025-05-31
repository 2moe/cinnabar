#!/usr/bin/env ruby
#
# frozen_string_literal
# ----------------
require_relative 'enter_ci_dir'
require 'open-uri'

url = 'https://github.com/2moe/argvise-gem/raw/refs/heads/main/lib/core.rb'
headers = {
  'User-Agent' => 'Mozilla/5.0 (Linux; aarch64 Wayland; rv:138.0) Gecko/20100101 Firefox/138.0'
}

Pathname('tmp').mkpath

URI.parse(url).open(**headers) do |response|
  file = Pathname 'tmp/argvise.rb'

  response
    .read
    .then { file.binwrite(it) }
end
