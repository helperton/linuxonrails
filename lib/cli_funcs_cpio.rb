require 'system_config'
require 'cli_funcs'

class Cpio < CliFuncs
  attr_accessor :rpm_file, :extract_dir, :cpio_data
  attr_reader :data_dir

  def initialize
    super
    @cpio_data
    @utility = CliUtils.new("cpio").utility_path
    @data_dir = SYSTEM_CONFIG["data_dir"]
    @extract_dir = ""
    set_extract_flags
  end

  def cpio
    begin
      FileUtils.mkdir_p @extract_dir unless Dir.exists? @extract_dir
      opts = { :chdir => @extract_dir, :err => "/dev/null" }
      io = IO.popen([@utility, flags_run].flatten, mode='r+', opts)
      io.puts @cpio_data
      io.close
      raise "Cpio data was zero in size, nothing extracted." if @cpio_data.length == 0
      puts [@utility, flags_run, opts].flatten.inspect if DEBUG
    rescue Exception => e
      puts "Tried to run #{@utility} #{@rpm_file} #{opts.inspect} during Cpio.cpio, received exception: #{e}"
    end
  end

  def set_extract_flags
    flags_extract_files
  end

  def flags_extract_files
    flag_add("-idm")
  end
end
