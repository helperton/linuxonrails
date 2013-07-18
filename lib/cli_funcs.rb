require 'system_config'
require 'cli_utils'

class CliFuncs
  attr_accessor :base_dir, :data_dir, :ignore_bad_exit, :flags_all
  attr_reader :output

  def initialize
    @ignore_bad_exit = false
    @base_dir = String
    @data_dir = String
    @output = Array.new
    @flags_all = Array.new
    set_dirs
  end

  def set_dirs
    @base_dir = SYSTEM_CONFIG["base_dir"]
    @data_dir = SYSTEM_CONFIG["data_dir"]
  end

  def flags_run
    @flags_all
  end

  def flag_add(flag)
    @flags_all.push(flag) unless flag == nil
  end

  def clear_values
    @flags_all = Array.new
    @output = Array.new
  end
  
  def run_and_capture(*args)
    args.flatten!
    begin
      puts "Args: #{args}" if DEBUG
      stdin, stdout_and_stderr, wait_thr = Open3.popen2e(*args)
      if(wait_thr.value.exitstatus != 0 unless @ignore_bad_exit)
        stdout_and_stderr.each do |line| 
          puts line 
        end
        raise "Ran #{args} and command with pid #{wait_thr.value.to_i} exited #{wait_thr.value.exitstatus}, error above."
      end
      stdout_and_stderr.each do |line|
        @output.push(line)
        p line if DEBUG
      end
    rescue Exception => e
      puts "Tried to run command: #{args[0, args.size]}, received exception: #{e}"
    end
  end
end
