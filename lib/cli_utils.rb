require 'open3'

class CliUtils
  attr_accessor :utility, :utility_path

  def initialize
    @utility
    @utility_path
    @version
  end

  def valid?
    find_utility
  end

  def find_utility
    cmd = "which #{@utility}"
    ph = IO.popen(cmd)
    output = ph.readlines()
    ph.close
    if($? != 0)
      puts "Cannot find required utility #{@utility} in path."
      false
    else
      @utility_path = output[0].chomp
      get_version
    end
  end

  def get_version
    version = Array.new
    if(@utility_path == nil)
      find_utility
    end
    cmd = "#{@utility_path} --version"
    Open3.popen2e(cmd) { |i,oe,t|
      oe.each do |line|
        version.push(line)
      end
    }

    @version = version.to_s

    supp_util_versions
  end

  def supp_util_versions
    case @utility
    when "rsync"
      supp_version = 3
      version_pattern.match(@version)
      if($1.to_s < supp_version.to_s)
        puts "Unsupported version of 'rsync', use version #{supp_version} or higher."
        false 
      else
        true
      end
    end
  end

  def version_pattern
    case @utility
    when "rsync"
      Regexp.new(/rsync  version ([\d\.]+)  protocol version (\d+)/)
    else
      puts "Not a supported utility: #{utility}"
      exit 1
    end
  end
end
