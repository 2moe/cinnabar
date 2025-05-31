# frozen_string_literal: true

require 'json'
require 'digest/sha2'
require 'digest/blake3'

def calculate_and_output_digests(glob_list = '*.zst', workdir = 'release')
  Pathname(workdir)
    .tap { _1.mkpath unless _1.exist? }
    .then { Dir.chdir _1 }

  digests = calculate_digests(glob_list)
  create_markdown_table(digests)
  generate_digests_json(digests)
end

def calculate_digests(file_glob_list = '*.zst') # rubocop:disable Metrics/MethodLength
  digests = {}
  Pathname.glob(file_glob_list).each do |path|
    file_name = path.basename
    sha256 = Digest::SHA256.file(path).hexdigest
    blake3 = Digest::Blake3.file(path).hexdigest

    digests[file_name] = {
      file_size: path.size?,
      digest: {
        sha256: sha256,
        blake3: blake3
      }
    }
  end
  digests
end

def create_markdown_table(digests)
  # mutable String
  markdown = String.new "| File   | Size (bytes)  | SHA256 | Blake3 |\n"
  markdown <<           "|--------|---------------|--------|--------|\n"

  digests.each do |file, info|
    digest = info[:digest]
    sha256 = digest[:sha256]
    blake3 = digest[:blake3]
    size   = info[:file_size]

    markdown << "| #{file} | #{size} | `#{sha256}` | `#{blake3}` |\n"
  end
  File.write('digests.md', markdown)
end

def generate_digests_json(digests)
  JSON.pretty_generate(digests)
      .then { File.write('digests.json', _1) }
end
