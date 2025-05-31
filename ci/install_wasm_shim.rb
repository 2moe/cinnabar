# frozen_string_literal: true

version = '0.6.0'
url = "https://github.com/containerd/runwasi/releases/download/containerd-shim-wasmtime%2Fv#{version}/containerd-shim-wasmtime-x86_64-linux-musl.tar.gz"

require 'open-uri'
require 'tmpdir'
Dir.mktmpdir do |dir|
  Dir.chdir(dir) do
    warn "Enter the temp dir: #{dir}"
    URI.open(url) do |response| # rubocop:disable Security/Open
      file = Pathname 'shim.tgz'
      response.read.then { file.binwrite(_1) }
    end
    %w[tar -xvf shim.tgz].then(&run)
    file = 'containerd-shim-wasmtime-v1'
    %W[sudo mv -vf #{file} /usr/local/bin/].then(&run)

    %({
      "features": {
        "containerd-snapshotter": true
      }
    }).then { File.write('daemon.json', _1) }
    %w[sudo mv -vf daemon.json /etc/docker/].then(&run)
  end
end

%w[sudo systemctl restart docker].then(&run)
