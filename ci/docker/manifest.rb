# frozen_string_literal: true

def create_and_push_manifest(repo: nil, tags: nil)
  main_image = "#{repo}:latest"

  # Create manifest
  %W[docker manifest create --amend #{main_image}]
    .concat(tags.map { "#{repo}:#{_1}" })
    .run_cmd

  # Push manifest
  %W[docker manifest push --purge #{main_image}]
    .run_cmd
end
