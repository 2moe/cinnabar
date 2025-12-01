# typed: true
# frozen_string_literal: true

module Kernel
  sig { params(uri: T.untyped).returns(URI::Generic) }
  def URI(uri); end # rubocop:disable Naming/MethodName

  sig { params(mod: Module).void }
  def import_methods(mod); end

  sig { params(port: T.untyped).void }
  def display(port = nil); end
end

class ::Array
  sig { returns(T::Boolean) }
  def run; end

  sig { returns(Integer) }
  def run_in_bg; end
end
