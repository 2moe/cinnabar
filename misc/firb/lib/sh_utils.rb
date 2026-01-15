# Depends: bat | batcat, eza
#
# frozen_string_literal: true

require_relative 'which'

BAT_CAT_CMD = -> {
  %w[bat batcat]
    .each { return [_1, '-Pp'] if which(_1) }
  ['cat']
}.call.freeze

EXA_LS_CMD = -> {
  %w[eza exa]
    .each { return [_1, '--icons=auto'] if which(_1) }
  ['ls', '--color=auto']
}.call.freeze

# Similar to `cd "/path/to/dir"; pwd; ls`
def cdir(path = Dir.home)
  path = path_sym_to_str(path)
  File
    .expand_path(path)
    .then { Dir.chdir _1 }
  puts Dir.pwd
  system(*EXA_LS_CMD)
end

def path_sym_to_str(path)
  path.is_a?(Symbol) ? path.to_s : path
end

def run_eza_ls(path = '.', *rest)
  cmd = EXA_LS_CMD.dup
  cmd.concat(rest) unless rest.empty?
  path = path_sym_to_str(path)
  cmd.push(File.expand_path(path))
  puts "\e[9m #{cmd} \e[0m"
  system(*cmd)
end
alias l run_eza_ls

def ll(path = '.', *rest)
  argv = %w[-l -h]
  argv.concat(rest) unless rest.empty?
  run_eza_ls(path, *argv)
end

def la(path = '.', *rest)
  argv = %w[-a -l -h]
  argv.concat(rest) unless rest.empty?
  run_eza_ls(path, *argv)
end

def cat(path, *rest)
  cmd = BAT_CAT_CMD.dup
  path = path_sym_to_str(path)
  cmd << File.expand_path(path)
  cmd.concat(rest) unless rest.empty?
  system(*cmd)
end

def pwd
  Dir.pwd
end
