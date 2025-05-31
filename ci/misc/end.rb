# ------------------
require 'pathname'

SCRIPT_DIR = Pathname(File.expand_path(__dir__))

def run = ->(cmd) do
  p cmd
  success = system(*cmd)
  raise "Command failed: #{cmd}" unless success
end

# run_in_background
def run_in_bg = ->(cmd) do
  p cmd
  Process.spawn(*cmd)
end

# Waits for a child process to complete and checks its status
#
# @raise [RuntimeError] if the process exits with non-zero status
#
# sig { params(pid: T.nilable(Integer)).void }
def wait_task(pid = nil)
  Process.wait(pid) if pid
  status = $?
  raise %(Command failed with "#{status}") unless status.success?
end

def require_ci(script)
  require SCRIPT_DIR.join(script)
end
# ------------------
load ARGV[0]
