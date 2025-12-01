# frozen_string_literal: true

module Cinnabar::Command
  module_function

  using Sinlog::Refin

  # This lambda function is capable of running system command.
  #
  # = Example
  #
  #     using Cinnabar::FnPipe::Refin
  #
  #     Cmd = Cinnabar::Command
  #     %w[sleep 3].▷ Cmd.run
  def run
    ->(array) do
      'Running system cmd'.log_dbg
      array.log_info
      success = system(*array)
      Kernel.raise "Command failed: #{array.join(' ')}" unless success
    end
  end

  # Lambda that runs system command in the background.
  #
  # @raise [RuntimeError] if the process exits with non-zero status
  #
  # = Example
  #
  #     Cmd = Cinnabar::Command
  #     pid = %w[sleep 5].then(&Cmd.run_in_bg)
  def run_in_bg
    ->(array) do
      'Running system cmd in the background'.log_dbg
      array.log_info
      Process.spawn(*array)
    end
  end

  # ---------------

  # Lambda that waits for a child process to complete and checks its status.
  #
  # This method requires the child process to exit with a successful status;
  # otherwise, it will raise an error.
  #
  # = Example
  #
  #     using Cinnabar::FnPipe::Refin
  #
  #     Cmd = Cinnabar::Command
  #     %w[sleep 3]
  #       .▷(Cmd.run_in_bg) #=> pid
  #       .▷(Cmd.wait_task)
  #
  def wait_task
    ->(pid) do
      "wait pid: #{pid}".log_dbg
      Process.wait(pid)
      status = $? # rubocop:disable Style/SpecialGlobalVars
      "child_status: #{status}".log_dbg
      Kernel.raise %(Command failed with "#{status}") unless status.success?
    end
  end
  # ---------------
end

module Cinnabar::Command
  module ArrayExt
    def run
      Cinnabar::Command.run.call(self)
    end

    # Spawns system command (runs in the background)
    def run_in_bg
      Cinnabar::Command.run_in_bg.call(self)
    end
  end

  # ---------------------

  # monkey patching: Array#run, Array#run_in_bg
  #
  # == Example
  #
  #     include Cinnabar::Command::ArrMixin
  #
  #     %w[ls -l].run
  #
  #     pid = %w[sleep 3].run_in_bg
  module ArrMixin
    def self.included(_host) = ::Array.include ArrayExt
  end

  # Refinements: Array#run, Array#run_in_bg
  #
  # = Examples
  #
  # == Simple
  #
  #     using Cinnabar::Command::ArrRefin
  #
  #     %w[ls -l].run
  #     #=> execute system('ls', '-l')
  #
  # == Argvise + run_in_bg
  #
  #     using Cinnabar::Command::ArrRefin
  #     using Argvise::HashRefin
  #
  #     pid = {
  #       cargo: (),
  #       run: (),
  #       target: "wasm32-wasip2"
  #     }.to_argv.run_in_bg
  #     #=> execute Process.spawn('cargo', 'run', '--target', 'wasm32-wasip2')
  #
  module ArrRefin
    refine ::Array do
      import_methods ArrayExt
    end
  end
end

module Cinnabar::Command
  module IntegerExt
    def wait_task
      Cinnabar::Command.wait_task.call(self)
    end
  end

  # ---------------------

  # Monkey Patching: Integer#wait_task
  #
  # == Example
  #
  #     include Cinnabar::Command::IntMixin
  #
  #     pid = %w[sleep 3].run_in_bg
  #     p "wait 3s"
  #     pid.wait_task
  module IntMixin
    def self.included(_host) = ::Integer.include IntegerExt
  end

  # Refinement: Integer#wait_task
  #
  # == Example
  #
  #     using Cinnabar::Command::IntRefin
  #
  #     pid = %w[sleep 3].run_in_bg
  #     p "wait 3s"
  #     pid.wait_task
  module IntRefin
    refine ::Integer do
      import_methods IntegerExt
    end
  end
end
