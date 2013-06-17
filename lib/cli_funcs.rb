require 'system_config.rb'
require 'cli_utils.rb'

class CliFuncs
  attr_accessor :basedir, :datadir, :output_filter
  attr_reader :output

  def initialize
    @basedir = String
    @datadir = String
    @output = Array.new
    @output_filter = String
    set_dirs
  end

  def get_env
    ENV['RSYNCONRAILS_CONFIG'] ||= "development"
  end

  def set_dirs
    @basedir = SYSTEM_CONFIG[get_env]["basedir"]
    @datadir = SYSTEM_CONFIG[get_env]["datadir"]
  end
  
  def run_and_capture(*args)
    args.flatten!
    debug = false
    begin
      puts "Args: #{args}" if debug
      stdin, stdout_and_stderr = Open3.popen2e(*args)
      stdout_and_stderr.each do |line|
        if line =~ /#{@output_filter}/ then 
          next 
        end
        @output.push(line)
        p line if debug
      end
    rescue Exception => e
      puts "Tried to run command: #{args[0, args.size]}, received exception: #{e}"
    end
  end
end

class Rsync < CliFuncs
  attr_accessor :flags_run, :cmd_run, :source, :destination, :output_filter
  attr_reader :uptodate, :deleted, :modified, :basedir, :datadir, :output

  def initialize
    super
    @uptodate = Array.new
    @deleted = Array.new
    @modified = Array.new
    @flags_all = Array.new
    @source = nil
    @destination = nil
    flags_base
    output_filters
  end

  def rsync
    run_and_capture(cmd_run)
  end

  def find_uptodate

  end

  def output_filters
    output_filters_junk
  end

  def output_filters_junk
    filter = Array.new

    # blank line
    filter.push("^$")
    # ignore line
    filter.push("^sending incremental file list")
    # ignore line
    filter.push("^building file list ...")
    # ignore line
    filter.push("^expand file_list\s\w+")
    # ignore line
    filter.push("^rsync: expand\s\w+")
    # ignore line
    filter.push("^opening connection\s\w+")
    # ignore line - should probably capture this info
    filter.push("^total")
    # ignore line - should probably capture this info
    filter.push("^wrote")
    # ignore line - should probably capture this info
    filter.push("^sent")
    # ignore line
    filter.push("^done")
    # ignore line
    filter.push("^excluding")
    # ignore line
    filter.push("^hiding")
    # ignore line
    filter.push("^delta( |-)transmission (dis|en)abled")
    # ignore line
    filter.push("^deleting in \./")

    @output_filter = filter.join("|")
  end

  def cmd_run
    u = CliUtils.new("rsync")
    [u.utility_path, flags_run, @source, @destination].flatten
  end
  
  def flags_run
    @flags_all
  end

  def flag_add(flag)
    @flags_all.push(flag) unless flag == nil
  end

  def flag_delete
    flag_add("--delete")
  end

  def flag_compress
    flag_add("-z")
  end

  def flag_dryrun 
    flag_add("-n")
  end

  def flag_verbose
    flag_add("-vv")
  end

  def flag_archive
    flag_add("-a")
  end

  def flag_itemized
    flag_add("-i")
  end

  def flag_checksum
    flag_add("-c")
  end

  def flag_bwlimit(kbps)
    flag_add("--bwlimit=#{kbps}")
  end

  def flag_rsync_path(path)
    flag_add("--rsync-path=#{path}")
  end

  def flags_base
    flag_archive
    flag_verbose
    flag_itemized
    flag_delete
  end
end
