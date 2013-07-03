require 'system_config'
require 'cli_utils'

class CliFuncs
  attr_accessor :base_dir, :data_dir
  attr_reader :output

  def initialize
    @base_dir = String
    @data_dir = String
    @output = Array.new
    set_dirs
  end

  def set_dirs
    @base_dir = SYSTEM_CONFIG["base_dir"]
    @data_dir = SYSTEM_CONFIG["data_dir"]
  end
  
  def run_and_capture(*args)
    args.flatten!
    begin
      puts "Args: #{args}" if DEBUG
      stdin, stdout_and_stderr = Open3.popen2e(*args)
      stdout_and_stderr.each do |line|
        @output.push(line)
        p line if DEBUG
      end
    rescue Exception => e
      puts "Tried to run command: #{args[0, args.size]}, received exception: #{e}"
    end
  end
end
