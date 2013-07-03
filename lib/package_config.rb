require 'system_config'
require 'find'

class PackageConfig
  attr_accessor :package, :package_yml, :package_base, :package_release_tag, :package_dir
  attr_reader :packages_dir

  def initialize(package="")
    @package = package
    @package_base = ""
    @package_release_tag = ""
    @package_yml = ""
    @package_dir = ""
    
    @packages_dir = SYSTEM_CONFIG['packages_dir']
  end

  def set_properties(obj)
    @package_base = obj.host_yml_values['config']['package_base']
    @package_release_tag = obj.host_yml_values['config']['release_tag']
    @package_dir = "#{@packages_dir}/#{@package_base}/#{package}/#{@package_release_tag}"
    @package_yml = "#{@package_dir}/package.yml"
  end

  def package_valid?
    if package_dir?
      if package_yml?
        return true
      else
        puts "Error: @package_yml: #{@package_yml} isn't valid!"
        return false
      end
    else
      puts "Error: @package_dir: #{@package_dir} does not exist!"
      return false
    end
  end

  def package_yml?
    File.exists? @package_yml
    yml_valid?
  end

  def yml_valid?
    begin
      package_yml = YAML.load_file(@package_yml)
      
      valid_keys = ['rank','include','exclude','exclude_backup','execute']
      
      # Begin check for basic elements
      package_yml.each_pair do |key,val|
        unless valid_keys.include? key
          puts "Invalid option => #{key} detected in #{@package_yml}.  Exiting..."
          return false
        end
      end
    rescue Exception => e
      puts "Tried to load #{@package_yml} during 'PackageConfig.yml_valid?', received exception: #{e}"
    end
  end

  def package_dir?
    # Package isn't valid unless it has a 'files' directory under it
    File.directory? "#{@package_dir}/files"
  end
end
