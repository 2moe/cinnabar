# frozen_string_literal: true

def install_gem(req: 'digest/blake3', gem_name: 'blake3-rb')
  begin
    require req
  rescue LoadError => e
    "ignore: #{e}".log_warn
  end

  %w[gem install --user-install].push(gem_name).run_cmd
end

def append_gem_bin_to_github_path
  case path = ENV['GITHUB_PATH']
    when nil, ''
      return ()
  end

  File.write(path.to_s, "#{Gem.user_dir}/bin\n", mode: 'a')
end
