require 'system_config'
require 'cli_funcs'

class Rpm2Cpio < CliFuncs
  attr_accessor :rpm_file, :flags_all
  attr_reader :output

  def initialize
    super
    @output
    @utility = CliUtils.new("rpm2cpio").utility_path
    @packages_dir = SYSTEM_CONFIG["packages_dir"]
    @default_dist = SYSTEM_CONFIG["default_dist"]
    @rpm_file = ""
  end

  def rpm2cpio
    # This should turn capture3 into binary mode just by being set
    opts = { :err => "/dev/null" }
    # Run our command and capture the binary output into @output
    begin
      IO.popen([@utility, @rpm_file].flatten, mode='r', opts) do |io|
        @output = io.read
      end
      puts [@utility, @rpm_file, opts].flatten.inspect if DEBUG
    rescue Exception => e
      puts "Tried to run #{@utility} #{@rpm_file} #{opts.inspect} during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end
end
