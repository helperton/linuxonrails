require 'system_config.rb'
require 'cli_utils.rb'

class CliFuncs
  attr_accessor :basedir, :datadir
  attr_reader :output

  def initialize
    @basedir
    @datadir
    @output = Array.new
    set_dirs
  end

  def get_env
    ENV['LINUXONRAILS_CONFIG'] ||= "development"
  end

  def set_dirs
    @basedir = SYSTEM_CONFIG[get_env]["basedir"]
    @datadir = SYSTEM_CONFIG[get_env]["datadir"]
  end
  
  def run_and_capture(cmd, *args)
    stdin = nil
    stdout_and_stderr = nil
    wait_thr = nil
    begin
      if(args.size == 0)
        stdin, stdout_and_stderr = Open3.popen2e(cmd)
        stdout_and_stderr.each do |line|
          @output.push(line)
        end
      else
        stdin, stdout_and_stderr = Open3.popen2e(cmd, Hash[*args])
        stdout_and_stderr.each do |line|
          @output.push(line)
        end
      end
    rescue Exception => e
      puts "Tried to run command: #{cmd} with arguments #{args}, received exception: #{e}"
    end
  end
end

class Rsync < CliFuncs
  attr_accessor :flags_run
  attr_reader :uptodate, :deleted, :modified, :basedir, :datadir, :output

  def initialize
    super
    @uptodate = Array.new
    @deleted = Array.new
    @modified = Array.new
    @flags_all = Hash.new(0)
    flags_base
  end

  def rsync(source,destination)
    u = CliUtils.new("rsync")
    run_and_capture(u.utility_path, flags_run, source, destination)
    puts @output
  end

  def flags_run
    #@flags_all.join(" ")
    @flags_all
  end

  def flag_add(flag)
    @flags_all[flag]
  end

  def flag_delete
    self."--delete"
  end

  def flag_compress
    "-z"
  end

  def flag_dryrun 
    "-n"
  end

  def flag_verbose
    "-vv"
  end

  def flag_archive
    "-a"
  end

  def flag_itemized
    "-i"
  end

  def flag_checksum
    "-c"
  end

  def flag_bwlimit(kbps)
    "--bwlimit=#{kbps}"
  end

  def flag_rsync_path(path)
    "--rsync-path=#{path}"
  end

  def flags_base
    @flags_all = { flag_archive
    @flags_all, flag_verbose, flag_itemized, flag_delete]
  end
end
