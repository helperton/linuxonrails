require 'system_config'
require 'cli_funcs'
require 'cli_funcs_rpm2cpio'
require 'cli_funcs_cpio'
require 'digest/sha1'


class Rpm < CliFuncs
  attr_accessor :rpm_file, :flags_all, :extract_dir
  attr_reader :control, :dependencies, :provides, :filelist, :scripts, :fpp

  def initialize
    super
    @utility ||= CliUtils.new("rpm").utility_path
    @packages_dir ||= SYSTEM_CONFIG["packages_dir"]
    @dist ||= SYSTEM_CONFIG["default_dist"]
    @rpm_file ||= ""
    @fpp = ""
    @rpp = ""
    @group = ""
    @name = ""
    @version = ""
    @arch = ""
    @extract_dir = ""
    @final_args = Array.new
    @control = Hash.new
    @output_filter_control = Array.new
    @dependencies = Hash.new
    @provides = Hash.new
    @filelist = Array.new
    @scripts = Hash.new
  end

  class RpmProvides < ActiveRecord::Base
  end
  
  class RpmDependencies < ActiveRecord::Base
  end
  
  class RpmPackages < ActiveRecord::Base
    validates_uniqueness_of :package_key
  end

  def run
    run_and_capture(cmd_run)
  end

  def rpm2cpio
    r = Rpm2Cpio.new
    r.rpm_file = @rpm_file
    r.rpm2cpio
    c = Cpio.new
    c.cpio_data = r.output
    c.extract_dir = "#{@fpp}/files"
    c.cpio
  end
    
  def package_exists?
    (File.exists? "#{@fpp}/files" and 
    File.exists? "#{@fpp}/redhat/info" and
    File.exists? "#{@fpp}/redhat/filelist" and 
    File.exists? "#{@fpp}/redhat/dependencies" and
    File.exists? "#{@fpp}/redhat/#{@rpm_file.split('/')[-1]}")
  end

  def create_package
    if package_exists?
      puts "Package exists..."
    else
      set_info
      prepare_package_dir
      write_info
      extract
    end
  end

  def extract
    # We have to copy the package to the files directory before we can run the rpm2cpio command
    begin
      FileUtils.cp(@rpm_file, "#{@fpp}/files")
    rescue Exception => e
      puts "Tried to copy #{@rpm_file} to #{@fpp}/files during #{self.class.name}.#{__method__}, received exception: #{e}"
    end

    # This should fill up @output with the archive content
    rpm2cpio

    # Move the rpm to the redhat directory for safe keeping
    begin
      FileUtils.mv("#{@fpp}/files/#{@rpm_file.split("/")[-1]}","#{@fpp}/redhat")
    rescue Exception => e
      puts "Tried to move #{@fpp}/files/#{@rpm_file.split("/")[-1]} to #{@fpp}/redhat during #{self.class.name}.#{__method__}, received exception: #{e}"
    end

  end

  def write_info
    write_control
    # Some packages don't have any scripts
    write_scripts unless @write_scripts == nil
    write_filelist
    write_provides_to_file
    write_provides_to_db
    write_dependencies_to_file
    write_dependencies_to_db
    write_package_to_db
  end
  
  def write_filelist
    begin
      f = open("#{@fpp}/redhat/filelist", 'w')
      @filelist.each do |file|
        f.puts file
      end
      f.close
    rescue Exception => e
      puts "Tried to open file #{@fpp}/redhat/filelist for writing during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end
  
  def write_dependencies_to_file
    begin
      f = open("#{@fpp}/redhat/dependencies", 'w')
      @dependencies.each_pair do |k,v|
        f.puts "#{k} #{v}"
      end
      f.close
    rescue Exception => e
      puts "Tried to open file #{@fpp}/redhat/dependencies for writing during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end

  def unique_package_key
    Digest::SHA1.hexdigest("#{@dist}#{@rpp}")
  end

  def write_package_to_db
    rpm = @rpm_file.split("/")[-1]
    RpmPackages.create(:package_key => unique_package_key, :dist => @dist, :rpp => @rpp, :rpm => rpm, :version => @version, :arch => @arch)
  end
  
  def write_dependencies_to_db
    @dependencies.each_pair do |k,v|
      RpmDependencies.create(:dependency => k, :version => v, :neededby => unique_package_key)
    end
  end

  def write_provides_to_db
    @provides.each_pair do |k,v|
      RpmProvides.create(:provides => k, :providedby => unique_package_key)
    end
  end

  def get_dependency
  end
  
  def write_provides_to_file
    begin
      f = open("#{@fpp}/redhat/provides", 'w+')
      @provides.each_pair do |k,v|
        f.puts "#{k} #{v}"
      end
      f.close
    rescue Exception => e
      puts "Tried to open file #{@fpp}/redhat/provides for writing during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end

  def write_control
    begin
      f = open("#{@fpp}/redhat/info", 'w')
      @control.each_pair do |k,v|
        f.puts "#{k}: #{v}"
      end
      f.close
    rescue Exception => e
      puts "Tried to open file #{@fpp}/redhat/info for writing during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end
  
  def write_scripts
    @scripts.each_pair do |k,v|
      #puts "KEY: #{k} VAL: #{v}"
      f = open("#{@fpp}/redhat/#{k}", 'w')
      f.print v
      f.close
    end
  end

  def set_pkg_info
    @group = @control["Group"].gsub(" ","_")
    @name = @control["Name"]
    @version = "#{@control["Version"]}-#{@control["Release"]}"
    @arch = @rpm_file.split("/")[-1].split(".")[-2]
    @rpp = "#{@group}/#{@name}.#{@arch}/#{@version}"
    @fpp = "#{@packages_dir}/#{@dist}/#{@rpp}"
  end

  def prepare_package_dir
    begin
      FileUtils.mkdir_p "#{@fpp}/files" unless File.exists? "#{@fpp}/files"
    rescue Exception => e
      puts "Tried to create #{@fpp}/files during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
    begin
      FileUtils.mkdir_p "#{@fpp}/redhat" unless File.exists? "#{@fpp}/redhat"
    rescue Exception => e
      puts "Tried to create #{@fpp}/redhat during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end

  def set_info
    initialize
    set_control
    set_dependencies
    set_provides
    set_filelist
    set_scripts
  end

  def set_scripts
    flags_query_package_scripts
    run
    output_process_scripts
    clear_values
  end
  
  def set_provides
    flags_query_package_provides
    run
    output_process_provides
    clear_values
  end
  
  def set_filelist
    flags_query_package_filelist
    run
    output_process_filelist
    clear_values
  end

  def set_dependencies
    flags_query_package_dependencies
    run
    output_process_dependencies
    clear_values
  end

  def set_control
    set_output_filter_control
    flags_query_package_control
    run
    output_process_control
    set_pkg_info
    clear_values
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
      puts "#{__FILE__.split("/")[-1]}:#{__LINE__}: #{line}" if DEBUG
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
    puts [u.utility_path, flags_run, @rpm_file, @final_args].flatten.inspect if DEBUG
    [u.utility_path, flags_run, @rpm_file, @final_args].flatten
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
end
