# rubocop:disable Naming/FileName
# typed: true
# frozen_string_literal: true

class ::Array
  sig do
    params(
      env_hash: T.nilable(Hash),
      opts: Hash
    ).returns(T.nilable(String))
  end
  def run(env_hash = nil, opts: {}); end

  sig do
    params(
      env_hash: T.nilable(Hash),
      opts: Hash
    ).returns([IO, Process::Waiter])
  end
  def async_run(env_hash = nil, opts: {}); end
end
