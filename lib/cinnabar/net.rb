# frozen_string_literal: true

module Cinnabar::Downloader
  module_function

  require 'open-uri'

  # == Example
  #
  #     url = 'https://docs.ruby-lang.org/en/3.4/OpenURI.html'
  #     opts = { out_dir: "tmp", file_name: "doc.html" }
  #     DL = Cinnabar::Downloader
  #     DL.download(url, opts)
  #
  # == Params
  #
  # - url: [String] e.g., https://url.local
  # - opts: [Hash] e.g., `{out_dir: 'download', file_name: nil, headers: {'User-Agent' => "aria2/1.37.0"}}`
  def download(url, opts)
    out_dir, file_name, headers = opts.values_at(:out_dir, :file_name, :headers)

    headers = build_headers(headers)
    parsed_url = Kernel.URI(url)
    final_file_name = determine_filename(file_name, parsed_url)
    file_path = setup_file_path(out_dir, final_file_name)

    Kernel.p file_path
    parsed_url
      .open(headers)
      .then { IO.copy_stream(_1, file_path.to_s) }
  end

  # => ::Hash
  def build_headers(headers)
    base_headers = {
      'User-Agent' => 'Mozilla/5.0 (Linux; aarch64 Wayland; rv:138.0) Gecko/20100101 Firefox/138.0',
    }
    base_headers.merge(headers || {}).transform_keys(&:to_s)
  end

  # => ::String
  def determine_filename(file_name, parsed_url)
    filename = file_name || File.basename(parsed_url.path || '')
    case filename.strip
      when '', '/' then 'index.html'
      else filename
    end
  end

  # => Kernel.Pathname
  def setup_file_path(out_dir, file_name)
    Kernel.Pathname(out_dir)
      .tap(&:mkpath)
      .join(file_name)
  end
end

module Cinnabar::Downloader
  module StringExt
    def download(out_dir: 'tmp', file_name: nil, headers: {})
      Cinnabar::Downloader.download(self, { out_dir:, file_name:, headers: })
    end
  end

  # -------------

  # = Example
  #
  #     include Cinnabar::Downloader::StrMixin
  #
  #     url = 'https://docs.ruby-lang.org'
  #
  #     url.download
  #     # OR: url.download(out_dir: "tmp", file_name: "custom.html")
  module StrMixin
    def self.included(_host) = ::String.include StringExt
  end

  # = Example
  #
  #     using Cinnabar::Downloader::StrRefin
  #
  #     url = 'https://docs.ruby-lang.org/en/master/OpenURI.html'
  #
  #     url.download
  #     # OR: url.download(out_dir: "/tmp", file_name: "index.html")
  module StrRefin
    refine ::String do
      import_methods StringExt
    end
  end
end
