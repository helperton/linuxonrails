require 'system_config'
require 'cli_funcs'

class Cpio < CliFuncs
  attr_accessor :rpm_file, :extract_dir, :cpio_data
  attr_reader :data_dir, :file_list

  def initialize
    super
    @cpio_data
    @file_list = Array.new
    @utility = CliUtils.new("cpio").utility_path
    @data_dir = SYSTEM_CONFIG["data_dir"]
    @extract_dir = ""
  end

  def cpio_extract
    set_extract_flags
    begin
      FileUtils.mkdir_p @extract_dir unless Dir.exists? @extract_dir
      opts = { :chdir => @extract_dir, :err => "/dev/null" }
      IO.popen([@utility, flags_run].flatten, mode='r+', opts) do |io|
        io.write @cpio_data
        io.close_write
      end
      raise "Cpio data was zero in size, nothing extracted." if @cpio_data.length == 0
      puts [@utility, flags_run, opts].flatten.inspect if DEBUG
    rescue Exception => e
      puts "Tried to run #{@utility} #{flags_run} #{opts.inspect} during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end
  
  def cpio_list
    set_list_flags
    begin
      opts = { :chdir => "/tmp", :err => "/dev/null" }
      IO.popen([@utility, flags_run].flatten, mode='r+', opts) do |io|
        io.write_nonblock @cpio_data
        io.close_write
        until io.eof?
          @file_list.push(io.readline.strip)
        end
      end 
      raise "Cpio data was zero in size, no files listed." if @cpio_data.length == 0
      puts [@utility, flags_run, opts].flatten.inspect if DEBUG
    rescue Exception => e
      puts "Tried to run #{@utility} #{flags_run} #{opts.inspect} during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end

  def set_extract_flags
    clear_values
    flags_extract_files
  end
  
  def set_list_flags
    clear_values
    flags_list_files
  end

  def flags_extract_files
    flag_add("-idm")
  end
  
  def flags_list_files
    flag_add("-it")
  end
end
