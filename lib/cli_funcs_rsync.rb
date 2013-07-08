require 'system_config'
require 'cli_funcs'

class Rsync < CliFuncs
  attr_accessor :flags_run, :cmd_run, :source, :destination
  attr_reader :uptodate, :deleted, :modified, :created, :excluded, :ignored, :duplicates, :base_dir, :data_dir, :output, :transfer_stats

  def initialize
    super
    @utility = "rsync"
    @uptodate = Array.new
    @deleted = Array.new
    @modified = Array.new
    @created = Array.new
    @excluded = Hash.new
    @ignored = Array.new
    @duplicates = Array.new
    @transfer_stats = Hash.new
    @flags_all = Array.new
    @source = Array.new
    @destination = String
    @output_filter_junk = Regexp
    @output_filter_excluded = Regexp
    @output_filter_warn_err = Regexp
    @output_filter_stats = Regexp
    @output_filter_duplicates = Regexp
    @output_filter_created = Regexp
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
    set_output_filter_stats
    set_output_filter_duplicates
    set_output_filter_created
  end

  def output_process
    @output.each do |line|
      if line.match @output_filter_junk
        next
      elsif line.match @output_filter_duplicates
        puts "#{line.chomp} DUPLICATE!" if DEBUG
        @duplicates.push(line)
        next
      elsif line.match @output_filter_excluded
        puts "#{line.chomp} EXCLUDED!" if DEBUG
        @excluded[$3] = $4
        next
      elsif line.match @output_filter_warn_err
        # Capture warnings / errors here
        next
      elsif line.match @output_filter_stats
        # Set hash of stats
        @transfer_stats[$1] = $2
        @transfer_stats[$3] = $4
        @transfer_stats[$5] = $6
        @transfer_stats[$7] = $8
        @transfer_stats[$9] = $10
        @transfer_stats[$11] = $12
        @transfer_stats[$13] = $14
        @transfer_stats[$15] = $16
        @transfer_stats[$17] = $18
        @transfer_stats[$19] = $20
        @transfer_stats[$21] = $22
        next
      elsif line.match @output_filter_created
        #@created.push(line)
        next
      else
        # catch all, this is the main content
        process_itemized(line)
      end
    end
    puts @transfer_stats.inspect if DEBUG
  end

  def process_itemized(line)
    # Break apart the line by spaces (e.g. ".f          9/file9")
    attrs,item = line.split(/\s+/, 2)
    # Break apart itemized attrs on each character 0 = . 1 = f 2 = nil, 3 = nil ...
    attrs_p = attrs.split("")
    # Begin check's for file/directory disposition according to rsync
    # If element 0 contains a '.', it means no update has occurred, but may have attribute changes
    if(attrs_p[0] == ".")
       # This first check ignores directories which have had their timestamp changed
       if(
          attrs_p[1] == "d" and 
          attrs_p[2] == "." and
          attrs_p[3] == "." and
          attrs_p[4] == "t" and
          attrs_p[5] == "." and
          attrs_p[6] == "." and
          attrs_p[7] == "." and
          attrs_p[8] == "." and
          attrs_p[9] == "." and
          attrs_p[10] == "."
       )
          puts "#{line.chomp} IGNORED!" if DEBUG
          @ignored.push(line)
          #return
       # checks if nothing has changed with this item
       elsif(
          attrs_p[1] =~ /f|d|L|D|S/ and 
          attrs_p[2] == nil and
          attrs_p[3] == nil and
          attrs_p[4] == nil and
          attrs_p[5] == nil and
          attrs_p[6] == nil and
          attrs_p[7] == nil and
          attrs_p[8] == nil and
          attrs_p[9] == nil and
          attrs_p[10] == nil
       )
          puts "#{line.chomp} UPTODATE!" if DEBUG
          @uptodate.push(line)
       # something must have changed, like an attribute (e.g. ownership or mode)
       else
          puts "#{line.chomp} MODIFIED OWNERSHIP OR MODE!" if DEBUG
          @modified.push(line) 
       end
    elsif(attrs_p[0] =~ /\*|<|>|c|h/)
      # checks if item is being deleted
      if(
         attrs_p[1] == "d" and 
         attrs_p[2] == "e" and
         attrs_p[3] == "l" and
         attrs_p[4] == "e" and
         attrs_p[5] == "t" and
         attrs_p[6] == "i" and
         attrs_p[7] == "n" and
         attrs_p[8] == "g" and
         attrs_p[9] == nil and
         attrs_p[10] == nil
      )
         puts "#{line.chomp} DELETED!" if DEBUG
         @deleted.push(line) 

      # checks if item is being created (i.e. new file/dir)
      elsif(
        attrs_p[1] =~ /f|d/ and 
        attrs_p[2] == "+" and
        attrs_p[3] == "+" and
        attrs_p[4] == "+" and
        attrs_p[5] == "+" and
        attrs_p[6] == "+" and
        attrs_p[7] == "+" and
        attrs_p[8] == "+" and
        attrs_p[9] == "+" and
        attrs_p[10] == "+"
      )
        puts "#{line.chomp} CREATED!" if DEBUG
        @created.push(line)

      # everthing else is considered a modification
      else
        puts "#{line.chomp} MODIFIED CATCH ALL 1!" if DEBUG
        @modified.push(line) 
      end
    else
      puts "#{line.chomp} MODIFIED CATCH ALL 2!" if DEBUG
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

    @output_filter_warn_err = /#{filter.join("|")}/
  end
  
  def set_output_filter_created
    filter = Array.new

    # These should be rare, for some reason it doesn't show up in the itemized list
    # and rsync doesn't count it as a 'created file', it seems like the only time 
    # this happens is if the destination root directory doesn't already exist.
    filter.push("^created directory .*")

    @output_filter_created = /#{filter[0]}/
  end

  def set_output_filter_stats
    filter = Array.new

    # These are for rsync stats which are output after the transfer is complete
    filter.push("(Number of files): (\\d+)")
    filter.push("(Number of files transferred): (\\d+)")
    filter.push("(Total file size): (\\d+) bytes")
    filter.push("(Total transferred file size): (\\d+) bytes")
    filter.push("(Literal data): (\\d+) bytes")
    filter.push("(Matched data): (\\d+) bytes")
    filter.push("(File list size): (\\d+)")
    filter.push("(File list generation time): (.*) seconds")
    filter.push("(File list transfer time): (.*) seconds")
    filter.push("(Total bytes sent): (\\d+)")
    filter.push("(Total bytes received): (\\d+)")

    @output_filter_stats = /#{filter.join("|")}/
  end

  def set_output_filter_excluded
    # These are files/directories which have been excluded by a pattern we passed to rsync
    @output_filter_excluded = /^\[generator\] (excluding|protecting) (file|directory) (.*) because of pattern (.*)$/
  end
    
  def set_output_filter_duplicates
    filter = Array.new

    # These are file/directories which are the same in the sources list
    filter.push("^removing duplicate name .* from file list .*")

    @output_filter_duplicates = /#{filter[0]}/
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
    # ignore line
    filter.push("^opening connection using: ssh")
    # ignore line
    filter.push("^rsync\\[\\d+\\] \\(sender\\) heap statistics:")
    # ignore line
    filter.push("^rsync\\[\\d+\\] \\(server receiver\\) heap statistics:")
    # ignore line
    filter.push("^rsync\\[\\d+\\] \\(server generator\\) heap statistics:")
    # ignore line
    filter.push("^  arena:")
    # ignore line
    filter.push("^  ordblks:")
    # ignore line
    filter.push("^  smblks:")
    # ignore line
    filter.push("^  hblks:")
    # ignore line
    filter.push("^  hblkhd:")
    # ignore line
    filter.push("^  allmem:")
    # ignore line
    filter.push("^  usmblks:")
    # ignore line
    filter.push("^  fsmblks:")
    # ignore line
    filter.push("^  uordblks:")
    # ignore line
    filter.push("^  fordblks:")
    # ignore line
    filter.push("^  keepcost:")

    @output_filter_junk = /#{filter.join("|")}/
  end

  def cmd_run
    u = CliUtils.new(@utility)
    puts [u.utility_path, flags_run, @source, @destination].flatten.inspect if DEBUG
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
  
  def flag_stats
    flag_add("--stats")
  end

  def flag_bwlimit(kbps)
    flag_add("--bwlimit=#{kbps}")
  end

  def flag_rsync_path(path)
    flag_add("--rsync-path=#{path}")
  end

  def flag_exclude(pattern)
    flag_add("--exclude=#{pattern[1..-1]}")
  end

  def set_flags_base
    flag_archive
    flag_verbose
    flag_itemized
    flag_delete
    flag_stats
  end
end
