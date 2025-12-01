# frozen_string_literal: true

module Cinnabar::FnPipe
  module_function

  def ▷(obj, other) # rubocop:disable Naming/MethodName
    callable =
      case other
        when Proc, Method then other
        when Symbol, String then Kernel.method(other)
        else Kernel.raise ArgumentError, "Unsupported type: #{other.class}"
      end
    callable.call(obj)
  end

  # alias 》 ▷
end

module Cinnabar::FnPipe
  module ObjectExt
    def ▷(other) # rubocop:disable Naming/MethodName
      Cinnabar::FnPipe.▷(self, other)
    end
  end

  # -------------

  # Function Pipe
  #
  # Monkey Patching: Object#▷
  #
  # = Example
  #
  #     include Cinnabar::FnPipe::Mixin
  #
  #     put_obj = ->s { puts s }
  #     'Foo'.▷(put_obj)
  #         #=> Foo
  #
  #     2.▷ :puts
  #         #=> 2
  module Mixin
    def self.included(_host) = ::Object.include ObjectExt
  end

  # Function Pipe
  #
  # Refinement: Object#▷
  #
  # = Example
  #
  #     using Cinnabar::FnPipe::Refin
  #
  #     put_obj = ->s { puts s }
  #     'Foo'.▷(put_obj)
  #         #=> put_obj.call('Foo') => puts 'Foo' => Foo
  #
  #     2.▷ put_obj
  #         #=> put_obj.call(2) => puts 2 => 2
  #
  #     'Bar'.▷ :puts
  #         #=> method(:puts).call('Bar') => puts 'Bar' => Bar
  #
  module Refin
    refine ::Object do
      import_methods ObjectExt
    end
  end
end
