# frozen_string_literal: true

version = '0.6.0'
url = "https://github.com/containerd/runwasi/releases/download/containerd-shim-wasmtime%2Fv#{version}/containerd-shim-wasmtime-x86_64-linux-musl.tar.gz"

require 'tmpdir'
Dir.mktmpdir do |dir|
  opts = { out_dir: dir, file_name: 'shim.tgz' }
  url.download(opts:)

  Dir.chdir(dir) do
    "Enter the temp dir: #{dir}".log_info

    %w[tar -xvf shim.tgz].run_cmd
    file = 'containerd-shim-wasmtime-v1'
    %W[sudo mv -vf #{file} /usr/local/bin/].run_cmd

    %({
      "features": {
        "containerd-snapshotter": true
      }
    }).then { File.write('daemon.json', _1) }
    %w[sudo mv -vf daemon.json /etc/docker/].run_cmd
  end
end

%w[sudo systemctl restart docker].run_cmd
