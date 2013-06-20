require 'system_config.rb'
require 'cli_utils.rb'

class CliFuncs
  attr_accessor :basedir, :datadir
  attr_reader :output

  def initialize
    @basedir = String
    @datadir = String
    @output = Array.new
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
        @output.push(line)
        p line if debug
      end
    rescue Exception => e
      puts "Tried to run command: #{args[0, args.size]}, received exception: #{e}"
    end
  end
end

class Rsync < CliFuncs
  attr_accessor :flags_run, :cmd_run, :source, :destination
  attr_reader :uptodate, :deleted, :modified, :excluded, :basedir, :datadir, :output, :output_processed

  def initialize
    super
    @uptodate = Array.new
    @deleted = Array.new
    @modified = Array.new
    @excluded = Array.new
    @flags_all = Array.new
    @source = String
    @destination = String
    @output_processed = Array.new
    @output_filter_junk = String
    @output_filter_excluded = String
    @output_filter_warn_err = String
    set_flags_base
    set_output_filters
  end

  def rsync
    run_and_capture(cmd_run)
  end

  def set_output_filters
    set_output_filter_junk
    set_output_filter_excluded
    set_output_filter_warn_err
  end

  def output_processed
    processed = Array.new
    @output.each do |line|
      if line =~ /#{@output_filter_junk}/ then
        next
      elsif line =~ /#{@output_filter_excluded}/ then
        # Capture excluded stuff here
      elsif line =~ /#{@output_filter_warn_err}/ then
        # Capture warnings / errors here
      else
        # catch all, this is the main content
        process_itemized(line)
      end
    end

    @uptodate.each do |line|
      puts line
    end
    @deleted.each do |line|
      puts line
    end
    @modified.each do |line|
      puts line
    end
  end

  def process_itemized(line)
    # Break apart the line by spaces (e.g. ".f          9/file9")
    attrs,item = line.split(/\s+/, 2)
    # Break apart itemized attrs on each character 0 = . 1 = f 2 = nil, 3 = nil ...
    attrs_p = attrs.split("")
    # Begin check's for file/directory disposition according to rsync
    if(attrs_p[0] ||= nil == "." and 
       attrs_p[1] ||= nil =~ /f|d|L|D/ and 
       attrs_p[2] ||= nil == nil and
       attrs_p[3] ||= nil == nil and
       attrs_p[4] ||= nil == nil and
       attrs_p[5] ||= nil == nil and
       attrs_p[6] ||= nil == nil and
       attrs_p[7] ||= nil == nil and
       attrs_p[8] ||= nil == nil
      )
      @uptodate.push(line)
    elsif(
       attrs_p[0] ||= nil == "*" and 
       attrs_p[1] ||= nil == "d" and 
       attrs_p[2] ||= nil == "e" and
       attrs_p[3] ||= nil == "l" and
       attrs_p[4] ||= nil == "e" and
       attrs_p[5] ||= nil == "t" and
       attrs_p[6] ||= nil == "i" and
       attrs_p[7] ||= nil == "n" and
       attrs_p[8] ||= nil == "g" 
      )
      @deleted.push(line) 
    else
      @modified.push(line) 
    end
  end

  def set_output_filter_warn_err
    filter = Array.new

    # These are warnings and errors kicked out by rsync during it's run
    filter.push("WARNING: .* failed verification -- update discarded \(will try again\)\.")
    filter.push("IO error encountered -- skipping file deletion")
    filter.push("file has vanished: .*")
    filter.push("rsync (error|warning): .*")
    filter.push("cannot delete non-empty directory: .*")

    @output_filter_warn_err = filter.join("|")
  end

  def set_output_filter_excluded
    filter = Array.new

    # These are files/directories which have been excluded by a pattern we passed to rsync
    filter.push("^(\[generator\]) (excluding|protecting) (directory|file) .* because of pattern .*$")

    @output_filter_excluded = filter.join("|")
  end

  def set_output_filter_junk
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

    @output_filter_junk = filter.join("|")
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

  def set_flags_base
    flag_archive
    flag_verbose
    flag_itemized
    flag_delete
  end
end
