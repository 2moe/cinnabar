# frozen_string_literal: true

require 'cinnabar'
using Cinnabar::StrToPath::Refin

def get_branch_name(file_name)
  file_name
    .to_path
    .basename
    .to_s
    .split('_')
    .last
end
