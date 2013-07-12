require 'system_config'
require 'cli_funcs'

class Rpm < CliFuncs
  attr_accessor :rpm_file
  attr_reader :control, :dependencies, :provides, :filelist, :scripts

  def initialize
    super
    @utility = "rpm"
    @rpm_file = ""
    @destination = ""
    @extracted = false
    @flags_all = Array.new
    @control = Hash.new
    @output_filter_control = Array.new
    @dependencies = Hash.new
    @provides = Hash.new
    @filelist = Array.new
    @scripts = Hash.new
  end

  def rpm
    run_and_capture(cmd_run)
  end

  def extracted?
    @extracted
  end

  def set_info
    set_control
    set_dependencies
    set_provides
    set_filelist
    set_scripts
  end

  def set_scripts
    flags_query_package_scripts
    rpm
    output_process_scripts
  end
  
  def set_provides
    flags_query_package_provides
    rpm
    output_process_provides
  end
  
  def set_filelist
    flags_query_package_filelist
    rpm
    output_process_filelist
  end

  def set_dependencies
    flags_query_package_dependencies
    rpm
    output_process_dependencies
  end

  def set_control
    set_output_filter_control
    flags_query_package_control
    rpm
    output_process_control
  end
  
  def output_process_scripts
    script = ""

    @output.each do |line|
      next if line.length == 0
      if line =~ /^(\w+)\sscriptlet\s/
        script = $1
        puts "SCRIPT: #{script}" if DEBUG
        next
      end
      if(@scripts[script] == nil)
        @scripts[script] = line
      else
        @scripts[script] << line
      end
    end
  end

  def output_process_control
    @output.each do |line|
      @output_filter_control.each do |pattern|
        if line =~ /#{pattern}/
          if(($1 and $2) and ($3 and $4))
            @control[$1.strip] = $2.strip
            @control[$3.strip] = $4.strip
          elsif($1 and $2)
            @control[$1.strip] = $2.strip
          end
        end
      end
    end
  end
  
  def output_process_dependencies
    @output.each do |line|
      pkg,ver = line.strip.chomp.split(/\s/, 2)
      if(ver == nil)
        @dependencies[pkg] = nil
      else
        @dependencies[pkg] = ver
      end
    end
  end

  def output_process_filelist
    @output.each do |line|
      @filelist.push(line.chomp)
    end
  end
  
  def output_process_provides
    @output.each do |line|
      pkg,ver = line.strip.chomp.split(" = ", 2)
      if(ver == nil)
        @provides[pkg] = nil
      else
        @provides[pkg] = ver
      end
    end
  end

  def set_output_filter_control
    # Name / Relocations
    @output_filter_control.push("^(Name)\s+: (.*)\s+(Relocations): (.*)$")
    # Version / Vendor
    @output_filter_control.push("^(Version)\s+: (.*)\s+(Vendor): (.*)$")
    # Release / Build Date
    @output_filter_control.push("^(Release)\s+: (.*)\s+(Build Date): (.*)$")
    # Install Date / Build Host
    @output_filter_control.push("^(Install Date): (.*)\s+(Build Host): (.*)$")
    # Group  / Source RPM
    @output_filter_control.push("^(Group)\s+: (.*)\s+(Source RPM): (.*)$")
    # Size / License
    @output_filter_control.push("^(Size)\s+: (.*)\s+(License): (.*)$")
    # Signature
    @output_filter_control.push("^(Signature)\s+: (.*)$")
    # Packager
    @output_filter_control.push("^(Packager)\s+: (.*)$")
    # URL
    @output_filter_control.push("^(URL)\s+: (.*)$")
    # Summary
    @output_filter_control.push("^(Summary)\s+: (.*)$")
    # We are not capturing 'Description' right now since there's no need
  end

  def cmd_run
    u = CliUtils.new(@utility)
    puts [u.utility_path, flags_run, @rpm_file, @destination].flatten.inspect if DEBUG
    [u.utility_path, flags_run, @rpm_file, @destination].flatten
  end
  
  def flags_run
    @flags_all
  end

  def flag_add(flag)
    @flags_all.push(flag) unless flag == nil
  end

  def flags_query_package_control
    flag_add("-qpi")
  end
  
  def flags_query_package_dependencies
    flag_add("-qpR")
  end
  
  def flags_query_package_provides
    flag_add("-qp")
    flag_add("--provides")
  end
  
  def flags_query_package_filelist
    flag_add("-qp")
    flag_add("--list")
  end
  
  def flags_query_package_scripts
    flag_add("-qp")
    flag_add("--scripts")
  end
  
  def clear_flags
    @flags_all = Array.new
  end
end
