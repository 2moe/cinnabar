# typed: false
# frozen_string_literal: true

module Cinnabar::Command
  module_function

  require 'open3'
  using Sinlog::Refin

  # Executes the command synchronously (blocking) and returns its standard output.
  #
  # @raise [RuntimeError] when `allow_failure: false` and the process exits with non-zero status
  #
  # @example pass env
  #
  #     Cmd = Cinnabar::Command
  #     cmd_arr = %w[sh -c] << 'printf $WW'
  #     env_hash = {WW: 2}
  #     opts = {allow_failure: true}
  #     output = Cmd.run(cmd_arr, env_hash, opts:)
  #     output.to_i == 2 #=> true
  #
  # @example pass stdin data
  #
  #     opts = {stdin_data: "Hello\nWorld\n"}
  #     output = Cinnabar::Command.run(%w[wc -l], opts:)
  #     output.to_i == 2 #=> true
  #
  # @param cmd_arr [Array<String>] The command and its arguments (e.g., `%w[printf hello]`).
  # @param env_hash [#to_h] Environment variables to pass to the command.
  # @param opts [Hash]
  #
  #   - Only the `:allow_failure` is extracted and handled explicitly;
  #   - all other keys are passed through to **Open3.capture2** unchanged.
  #
  # @option opts [Boolean] :allow_failure
  #   Indicates whether the command is allowed to fail.
  #
  # @return [String, nil] the standard output of the command.
  #
  # @see async_run
  def run(cmd_arr, env_hash = nil, opts: {}) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    'Running and capturing the output of a system command.'.log_dbg
    cmd_arr.log_info
    "opts: #{opts}".log_dbg

    allow_failure = opts.delete(:allow_failure) || false

    final_env = normalize_env(env_hash)

    begin
      stdout, status =
        if final_env.nil?
          Open3.capture2(*cmd_arr, opts)
        else
          Open3.capture2(final_env, *cmd_arr, opts)
        end
    rescue StandardError => e
      Kernel.raise e unless allow_failure
      e.log_err
      return stdout
    end

    return stdout if status.success?

    err_msg = "Command failed: #{cmd_arr.join(' ')}"
    Kernel.raise err_msg unless allow_failure

    err_msg.log_err
    stdout
  end

  # Executes a system command using Ruby's `Kernel.system`.
  #
  # It runs the command synchronously, blocks until completion, and does not capture stdout or stderr.
  #
  # @param cmd_arr [Array<String>] The command and its arguments as an array,
  #   e.g., `%w[ls -lh]`.
  #
  # @param env_hash [#to_h] Environment variables to pass to the command.
  # @param opts [Hash]
  #
  #   - Only the `:allow_failure` is extracted and handled explicitly;
  #   - all other keys are passed through to `Kernel.system` unchanged.
  #
  # @option opts [Boolean] :allow_failure
  #   Indicates whether the command is allowed to fail.
  #   If true, the method will return false instead of raising an exception when the
  #   command exits with a non-zero status.
  #
  # @see https://docs.ruby-lang.org/en/3.4/Process.html#module-Process-label-Execution+Options
  #
  # @example pwd
  #
  #     Cmd = Cinnabar::Command
  #     opts = {chdir: '/tmp', allow_failure: true}
  #     Cmd.run_cmd(%w[pwd], opts:)
  #
  # @example pass env
  #
  #     Cmd = Cinnabar::Command
  #     cmd_arr = %w[sh -c] << 'printf $WW'
  #     env_hash = {WW: 2}
  #     Cmd.run_cmd(cmd_arr, env_hash)
  #
  # @return [Boolean] Returns true if the command succeeds (exit status 0),
  #   or false if it fails and `allow_failure` is true.
  # @raise [RuntimeError] Raises an error if the command fails and `allow_failure` is false.
  def run_cmd(cmd_arr, env_hash = nil, opts: {})
    'Running system command'.log_dbg
    cmd_arr.log_info
    "opts: #{opts}".log_dbg

    allow_failure = opts.delete(:allow_failure) || false
    exception = !allow_failure
    "exception: #{exception}".log_dbg
    options = opts.merge({ exception: })

    final_env = normalize_env(env_hash)
    if final_env.nil?
      Kernel.system(*cmd_arr, options)
    else
      Kernel.system(final_env, *cmd_arr, options)
    end
  end

  # @param hash [#to_h]
  # @return [Hash{String => String}, nil] a hash where both keys and values are strings
  def normalize_env(hash)
    return nil if hash.nil?
    return nil if hash.respond_to?(:empty?) && hash.empty?

    hash.to_h { |k, v| [k.to_s, v.to_s] }
      .tap { "normalized_env:#{_1}".log_dbg }
  end

  # Launch a command asynchronously (non-blocking) and return its stdout stream and process waiter.
  #
  # This is a sugar over **Open3.popen2**, intended to start a subprocess
  # and **immediately** hand back:
  #
  #    1. an `IO` for reading the command's stdout, and
  #    2. a `Process::Waiter` (a thread-like object) that can be awaited later.
  #
  # - If `:stdin_data` is provided, the data will be written to
  #   the child's stdin and the stdin will be closed.
  # - When `:stdin_data` is absent, stdin is simply closed and
  #   the method returns immediately without blocking on output.
  #
  # @param cmd_arr [Array<String>] The command and its arguments (e.g., `%w[printf hello]`).
  # @param env_hash [#to_h] Optional environment variables;
  #   keys/values will be normalized by {#normalize_env} before being passed to the child.
  #
  # @param opts [Hash] Additional options.
  #
  #   - Only the following keys are extracted and handled explicitly;
  #     - :stdin_data
  #     - :binmode
  #     - :stdin_binmode
  #     - :stdout_binmode
  #
  #   all other keys are passed through to **Open3.popen2** unchanged.
  #
  # @option opts [String, #readpartial] :stdin_data
  #   Data to write to the child's stdin. If it responds to `#readpartial`,
  #   it will be streamed via **IO.copy_stream**;
  #
  # @option opts [Boolean] :binmode
  #   When `true`, set both stdin and stdout to binary mode (useful for binary data).
  #
  # @option opts [Boolean] :stdin_binmode
  #   Sets only stdin to binary mode.
  #
  # @option opts [Boolean] :stdout_binmode
  #   Sets only stdout to binary mode.
  #
  # @return [Array(IO, Process::Waiter)] A pair `[stdout_io, waiter]`:
  #
  #   - `stdout_io` is an `IO` for reading **stdout**
  #   - `waiter` is a `Process::Waiter`;
  #     - call `waiter.value` to get `Process::Status`;
  #     - or `waiter.join` to block until the process exits.
  #
  # @raise [StandardError] Reraises any non-`Errno::EPIPE` exception encountered while writing to stdin.
  #   `Errno::EPIPE` is logged and swallowed.
  #
  # @example start a process and later wait for it
  #
  #     Cmd = Cinnabar::Command
  #     stdout_fd, waiter = Cmd.async_run(['sh', '-c', 'echo hello; sleep 1; echo done'])
  #
  #     output, status = Cmd.wait_with_output(stdout_fd, waiter)
  #
  # @example pass stdin data
  #
  #     Cmd = Cinnabar::Command
  #     opts = {stdin_data: "Run in the background" }
  #     io_and_waiter = Cmd.async_run(%w[wc -m], opts:)
  #
  #     output, status = Cmd.wait_with_output(*io_and_waiter)
  #     status.success?   #=> true
  #     output.to_i == 21 #=> true
  #
  # @see wait_with_output
  # @see run
  def async_run(cmd_arr, env_hash = nil, opts: {}) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    "Asynchronously executing system command: #{cmd_arr}".log_dbg
    "opts: #{opts}".log_dbg

    stdin_data = opts.delete(:stdin_data)
    binmode = opts.delete(:binmode)
    stdin_binmode = opts.delete(:stdin_binmode)
    stdout_binmode = opts.delete(:stdout_binmode)

    'async_run() does not support the :allow_failure option.'.log_warn if opts.delete(:allow_failure)

    final_env = normalize_env(env_hash)

    stdin, stdout, waiter =
      if final_env.nil?
        Open3.popen2(*cmd_arr, opts)
      else
        Open3.popen2(final_env, *cmd_arr, opts)
      end

    if binmode
      stdin.binmode
      stdout.binmode
    else
      stdin.binmode if stdin_binmode
      stdout.binmode if stdout_binmode
    end

    # Non-blocking: no stdin to write; return immediately
    unless stdin_data
      stdin.close
      return [stdout, waiter]
    end

    begin
      if stdin_data.respond_to? :readpartial
        IO.copy_stream(stdin_data, stdin)
      else
        stdin.write stdin_data
      end
    rescue Errno::EPIPE => e
      e.log_err
    rescue StandardError => e
      "Failed to write stdin data: #{e}".log_err
      Kernel.raise e
    ensure
      stdin.close
    end
    [stdout, waiter]
  end

  # Waits for a process to finish and reads all remaining output from its stdout.
  #
  # @param io_fd [IO] The IO object connected to the process's stdout (or combined stdout & stderr).
  # @param waiter [Process::Waiter] The waiter thread returned by **Open3.popen2** or **Open3.popen2e**.
  #
  # @return [Array(String, Process::Status)] A two-element array:
  #
  #   - The full output read from `io_fd`.
  #   - The **Process::Status** object representing the process's exit status.
  #
  # @example Wait for process and capture output
  #
  #   require 'sinlog'
  #   using Sinlog::Refin
  #
  #   Cmd = Cinnabar::Command
  #
  #   fd, waiter = %w[ruby -e].push('sleep 2; puts "OK"')
  #                 .then { Cmd.async_run(_1) }
  #
  #   "You can now do other things without waiting for the process to complete.".log_dbg
  #
  #   "blocking wait".log_info
  #   output, status = Cmd.wait_with_output(fd, waiter)
  #
  #   "Exit code: #{status.exitstatus}".log_warn unless status.success?
  #   "Output:\n#{output}".log_info
  #
  # @note This method blocks until the process exits and all output is read.
  # @see async_run
  def wait_with_output(io_fd, waiter)
    status = waiter.value
    output = io_fd.read
    io_fd.close
    [output, status]
  end
end

module Cinnabar::Command
  # The foundation of {ArrRefin} and {ArrMixin}
  # @see Cinnabar::Command.run
  # @see Cinnabar::Command.async_run
  # @see Cinnabar::Command.run_cmd
  module ArrExt
    # Executes the command synchronously (blocking) and returns its standard output.
    #
    # @note self [`Array<String>`]: The command and its arguments (e.g., `%w[printf hello]`).
    #
    # @param env_hash [#to_h] Environment variables to pass to the command.
    # @param opts [Hash]
    #
    #   - Only the `:allow_failure` is extracted and handled explicitly;
    #   - all other keys are passed through to **Open3.capture2** unchanged.
    #
    # @raise [StandardError] when `allow_failure: false` and the process exits with non-zero status
    #
    # @return [String, nil] the standard output of the command.
    # @see Cinnabar::Command.run
    #
    # @example pass stdin data
    #
    #     using Cinnabar::Command::ArrRefin
    #     # OR: include Cinnabar::Command::ArrMixin
    #
    #     opts = {allow_failure: true, stdin_data: "Hello\nWorld\n"}
    #     output = %w[wc -l].run(opts:)
    #     output.to_i == 2 unless output.nil? #=> true
    #
    # @note This method blocks until the process completes.
    def run(env_hash = nil, opts: {})
      Cinnabar::Command.run(self, env_hash, opts:)
    end

    # Starts a command asynchronously using this `Array<String>`.
    #
    # @note self [`Array<String>`]: The command and its arguments (e.g., `%w[printf hello]`).
    #
    # @param env_hash [#to_h] Optional environment variables.
    # @param opts [Hash]
    #
    # @see Cinnabar::Command.async_run
    #
    # @return [Array(IO, Process::Waiter)] a pair `[stdout_io, waiter]`
    #
    # @example pass stdin data
    #
    #     using Cinnabar::Command::ArrRefin
    #     # OR: include Cinnabar::Command::ArrMixin
    #
    #     opts = {stdin_data: "Hello\nWorld\n"}
    #     io_and_waiter = %w[wc -l].async_run(opts:)
    #     output, status = Cinnabar::Command.wait_with_output *io_and_waiter
    #     output.to_i == 2 #=> true
    def async_run(env_hash = nil, opts: {})
      Cinnabar::Command.async_run(self, env_hash, opts:)
    end

    # @note self [`Array<String>`]: The command and its arguments (e.g., `%w[printf hello]`).
    #
    # @example pwd
    #
    #     using Cinnabar::Command::ArrRefin
    #     # OR: include Cinnabar::Command::ArrMixin
    #
    #     opts = {chdir: '/tmp', allow_failure: true}
    #     status = %w[pwd].run_cmd(opts:)
    #
    # @example pass env
    #
    #     using Cinnabar::Command::ArrRefin
    #
    #     env_hash = {WW: 2}
    #     status =
    #        %w[sh -c]
    #          .push('printf $WW')
    #          .run_cmd(env_hash)
    #
    #     status == true
    #
    # @return [Boolean]
    # @see Cinnabar::Command.run_cmd
    def run_cmd(env_hash = nil, opts: {}) # rubocop:disable Style/OptionalBooleanParameter
      Cinnabar::Command.run_cmd(self, env_hash, opts:)
    end
  end

  # ---------------------

  # Monkey patching: Array#run, Array#async_run, Array#run_cmd
  #
  # @example run
  #
  #     include Cinnabar::Command::ArrMixin
  #
  #     stdout = %w[printf World].run
  #     stdout == "World" #=> true
  #
  # @example async_run
  #
  #     include Cinnabar::Command::ArrMixin
  #
  #     fd, waiter = %w[ruby -e].push('sleep 2; puts "OK"').async_run
  #
  #     status = waiter.value
  #     status.success?  #=> true
  #
  #     output = fd.read.chomp
  #     fd.close
  #     output == 'OK' #=> true
  #
  # @example async_run + wait_with_output
  #
  #     include Cinnabar::Command::ArrMixin
  #     include Cinnabar::Command::TaskArrMixin
  #
  #     task = %w[ruby -e].push('sleep 2; puts "OK"').async_run
  #
  #     output, status = task.wait_with_output
  #
  #     status.success?  #=> true
  #     output.chomp == 'OK' #=> true
  #
  # @see ArrExt
  module ArrMixin
    def self.included(_host) = ::Array.include ArrExt
  end

  # Refinements: Array#run, Array#async_run, Array#run_cmd
  #
  # @example run
  #
  #     using Cinnabar::Command::ArrRefin
  #
  #     stdout =
  #       %w[ruby -e]
  #         .push('print 2')
  #        .run
  #
  #     stdout.to_i == 2   #=> true
  #
  # @example run(opts:)
  #
  #     using Cinnabar::Command::ArrRefin
  #
  #     opts = { allow_failure: true, stdin_data: "Hello" }
  #
  #     stdout = %w[wc -m].run(opts:)
  #
  #     stdout.to_i == 5   #=> true
  #
  # @example Argvise + run_async
  #
  #     require 'argvise'
  #     require 'cinnabar'
  #
  #     using Argvise::HashRefin
  #     using Cinnabar::Command::ArrRefin
  #     using Cinnabar::Command::TaskArrRefin
  #
  #     task = {
  #       cargo: (),
  #       b: (),
  #       r: true,
  #       target: "wasm32-wasip2"
  #     }
  #       .to_argv
  #       .run_async
  #
  #     stdout, status = task.wait_with_output
  #     status.success? #=> true
  #
  # @see ArrExt
  module ArrRefin
    refine ::Array do
      import_methods ArrExt
    end
  end
end

module Cinnabar::Command
  # The foundation of {TaskArrRefin} and {TaskArrMixin}
  # @see Cinnabar::Command.wait_with_output
  #
  # @example simple
  #
  #     using Cinnabar::Command::ArrRefin
  #     using Cinnabar::Command::TaskArrRefin
  #     # OR: include Cinnabar::Command::TaskArrMixin
  #
  #     task = %w[ruby -e]
  #             .push('sleep 2; puts "OK"')
  #             .async_run
  #
  #     stdout, status = task.wait_with_output
  #     status.success? #=> true
  module TaskArrExt
    def wait_with_output
      Cinnabar::Command.wait_with_output(*self)
    end
  end

  # Refinement: Array#wait_with_output
  # @see TaskArrExt
  module TaskArrRefin
    refine ::Array do
      import_methods TaskArrExt
    end
  end

  # Monkey Patching: Array#wait_with_output
  # @see TaskArrExt
  module TaskArrMixin
    def self.included(_host) = ::Array.include TaskArrExt
  end
end
