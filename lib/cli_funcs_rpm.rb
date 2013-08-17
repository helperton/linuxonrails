require 'system_config'
require 'cli_funcs'
require 'cli_funcs_rpm2cpio'
require 'cli_funcs_cpio'
require 'digest/sha1'

class Rpm < CliFuncs
  attr_accessor :rpm_file, :flags_all, :extract_dir, :dist, :fpp, :rpp
  attr_reader :control, :dependencies, :provides, :filelist, :scripts, :packages_dir

  def initialize
    super
    @utility ||= CliUtils.new("rpm").utility_path
    @packages_dir ||= SYSTEM_CONFIG["packages_dir"]
    @dist ||= SYSTEM_CONFIG["default_dist"]
    @rpm_file ||= ""
    @pp = ""
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
    @cpio = Cpio.new
    @rpm2cpio = Rpm2Cpio.new
  end

  require 'models/rpm_packages'
  require 'models/rpm_provides'
  require 'models/rpm_dependencies'

  def run
    run_and_capture(cmd_run)
  end

  def set_cpio_data 
    @rpm2cpio.rpm_file = @rpm_file
    @rpm2cpio.rpm2cpio
    @cpio.cpio_data = @rpm2cpio.output
  end

  def set_cpio_filelist
    @cpio.cpio_list
  end

  def cpio_extract
    @cpio.extract_dir = "#{@fpp}/files"
    @cpio.cpio_extract
  end
    
  def package_exists?
    if !File.exists? "#{@fpp}/files"
      puts "Package missing '#{@fpp}/files' directory" if DEBUG
      return false
    elsif !File.exists? "#{@fpp}/redhat/info"
      puts "Package missing '#{@fpp}/redhat/info'" if DEBUG
      return false
    elsif !File.exists? "#{@fpp}/redhat/filelist"
      puts "Package missing '#{@fpp}/redhat/filelist'" if DEBUG
      return false
    elsif !File.exists? "#{@fpp}/redhat/dependencies"
      puts "Package missing '#{@fpp}/redhat/dependencies'" if DEBUG
      return false
    elsif !File.exists? "#{@fpp}/redhat/#{@rpm_file.split('/')[-1]}"
      puts "Package missing '#{@fpp}/redhat/#{@rpm_file.split('/')[-1]}'" if DEBUG
      return false
    elsif package_missing_files?
      return false
    else
      return true
    end
  end

  def package_missing_files?
    return false if @cpio.file_list.size == 0
    @cpio.file_list.each do |f| f.gsub!("./","")
      unless file_dir_or_symlink_exists? "#{@fpp}/files/#{f}"
        puts "Package missing '#{@fpp}/files/#{f}'" if DEBUG
        return true
      end
    end
    false
  end

  def file_dir_or_symlink_exists?(path)
    File.exist?(path) || File.symlink?(path)
  end

  def preprocess_package
    print "Pre-Processing file #{@rpm_file}..." if DEBUG
    set_info
    write_info_db
  end

  def create_package
    print "Processing file #{@rpm_file}..." if DEBUG
    set_info
    if package_exists?
      puts "Package #{@fpp} exists." if DEBUG
    else
      prepare_package_dir
      write_info
      extract
      puts "package created in #{@fpp}." if DEBUG
    end
  end

  def extract
    # We have to copy the package to the files directory before we can run cpio_extract
    begin
      FileUtils.cp(@rpm_file, "#{@fpp}/files")
    rescue Exception => e
      puts "Tried to copy #{@rpm_file} to #{@fpp}/files during #{self.class.name}.#{__method__}, received exception: #{e}"
    end

    # This should fill up @output with the archive content
    cpio_extract

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
    write_scripts
    write_filelist
    write_provides_to_file
    write_dependencies_to_file
    write_info_db
  end

  def write_info_db
    write_provides_to_db
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

  def get_rpm_file(dist=@dist, rpp=@rpp)
    set_fpp
    "#{@fpp}/redhat/#{Rpm::RpmPackages.where(:package_key => unique_package_key).first.rpm}"
  end

  def set_fpp
    @fpp = "#{@packages_dir}/#{@dist}/#{@rpp}"
    @pp = @fpp.split('/')[0..-2].join('/')
  end

  def write_package_to_db
    rpm = @rpm_file.split("/")[-1]
    Rpm::RpmPackages.create(:package_key => unique_package_key, :dist => @dist, :rpp => @rpp, :rpm => rpm, :version => @version, :arch => @arch)
  end
  
  def write_dependencies_to_db
    @dependencies.each_pair do |k,v|
      Rpm::RpmDependencies.create(:dependency => k, :version => v, :neededby => unique_package_key)
    end
  end

  def write_provides_to_db
    @provides.each_pair do |k,v|
      Rpm::RpmProvides.create(:provides => k, :providedby => unique_package_key)
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
    return true if @scripts == nil
    @scripts.each_pair do |k,v|
      puts "KEY: #{k} VAL: #{v}" if DEBUG
      f = open("#{@fpp}/redhat/#{k}", 'w')
      f.print v
      f.close
    end
  end

  def delete_package
    set_info
    delete_fs_entry
    delete_db_entry
  end

  def delete_db_entry
    puts "Removing #{@dist}/#{@rpp} with unique key of #{unique_package_key}" if DEBUG
    Rpm::RpmPackages.where(:package_key => unique_package_key).delete_all
    Rpm::RpmProvides.where(:providedby => unique_package_key).delete_all
    Rpm::RpmDependencies.where(:neededby => unique_package_key).delete_all
  end

  def delete_fs_entry
    begin
      puts "Removing #{@fpp}" if DEBUG
      FileUtils.rm_rf(@fpp)
      FileUtils.rmdir(@pp) if Dir.entries(@pp).size <= 2
    rescue Exception => e
      puts "Tried to remove filesystem entry for #{@fpp} during #{self.class.name}.#{__method__}, received exception: #{e}"
    end
  end

  def set_pkg_info
    @group = @control["Group"].gsub(" ","_")
    @name = @control["Name"]
    @version = "#{@control["Version"]}-#{@control["Release"]}"
    @arch = @rpm_file.split("/")[-1].split(".")[-2]
    @rpp = "#{@group}/#{@name}.#{@arch}/#{@version}"
    set_fpp
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
    set_cpio_data
    set_cpio_filelist
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
      puts "SCRIPT LINE: #{line}" if DEBUG
      if line =~ /^(\w+)\sscriptlet\s/
        script = $1
        puts "SCRIPT: #{script}" if DEBUG
        next
      elsif line =~ /^(\w+)\sprogram:\s(.*)/
        script = $1
        line = $2
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
