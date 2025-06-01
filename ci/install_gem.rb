def install_gem(req: 'digest/blake3', gem_name: 'blake3-rb')
  require req
rescue LoadError => e
  warn "ignore: #{e}"

  case path = ENV['GITHUB_PATH']
  in nil | ''
  else
    File.write(path.to_s, "#{Gem.user_dir}/bin\n", mode: 'a')
  end

  %w[gem install --user-install].push(gem_name).then(&run)
end
