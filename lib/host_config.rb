require 'system_config'
require 'find'

class HostConfig
  attr_accessor :host, :domain, :host_yml, :autocreate
  attr_reader :hosts_dir, :host_dir, :found_host, :host_yml_values

  def initialize(hostname="")
    @autocreate = false
    @hostname = hostname
    @host = ""
    @domain = ""
    @host_dir = ""
    @host_yml = ""
    @found_host = ""
    @host_yml_values = Hash.new
    
    @hosts_dir = SYSTEM_CONFIG['hosts_dir']
    prepare_hosts_dir
    set_hostname_domain
  end

  def set_hostname_domain
    if @hostname.include? "."
      @host = @hostname.split(".").shift
      @domain = @hostname.split(".")[1..-1].join(".")
    else
      @host = @hostname
      @domain = ""
    end
  end

  def find_host
    begin
        Find.find(@hosts_dir) do |path|
          # These are the 3 things which define a 'host' in the system, 2 if there's no domain
          if path =~ /#{@domain}/ and path =~ /#{@host}$/ and File.directory? "#{path}/overrides"
            @host_dir = path  
            @host_yml = "#{@host_dir}/host.yml"
            # Since this is a path with more than just the domain and hostname in it,
            # we need to test if this is a hostname without a domain in front. If so
            # we need to set @found_host differently. We test to see if the full path
            # minus the hostname is equal to the '@hosts_dir' because someone might
            # name create a host without it having a domain component.
            if "/#{path.split('/')[1..-2].join('/')}" == @hosts_dir
              # If we get here, it means this path did not have a domain component
              @found_host = "#{path.split('/')[-1]}"
            else
              # This path did have a domain component
              @found_host = "#{path.split('/')[-2]}/#{path.split('/')[-1]}"
            end
            # This should set @host_yml_values
            unless host_valid?
              return false
            end
          else
            prepare_host
          end
        end
    rescue Exception => e
      puts "Tried to find host: #{@hostname} in #{@hosts_dir} during HostConfig.find_host, received exception #{e}"
      exit 1
    end
  end

  def prepare_host
    if @autocreate
      @host_dir = "#{@hosts_dir}/#{@domain}/#{@host}"
      @host_yml = "#{@host_dir}/host.yml"
      # This should set @host_yml_values
      unless host_valid? 
        return false 
      end
    end
  end

  def host_valid?
    if host_dir?
      if host_yml?
        return true
      else
        puts "Host yml isn't valid"
        return false
      end
    else
      puts "Host directory isn't valid."
      return false
    end
  end

  def host_yml?
    unless File.exists? @host_yml then
      prepare_host_yml
      yml_valid?
    else
      yml_valid?
    end
  end

  def prepare_host_yml
    begin
      f = open(@host_yml, 'w+')
      f.puts "config:"
      f.puts "  package_base: test_dist"
      f.puts "  release_tag: current"
      f.puts "  rsync_path:"
      f.puts "  ssh_port:"
      f.puts "  session_mode:"
      f.puts "include:"
      f.puts "  # - section/packagename"
      f.puts "exclude:"
      f.puts "  # - /somefile"
      f.puts "exclude_backup:"
      f.puts "  # - /somefile"
      f.puts "execute:"
      f.puts "  # - some arbitrary command"
      f.close
    rescue Exception => e
      puts "Tried to open #{@host_yml} during 'HostConfig.prepare_host_yml', received exception: #{e}"
      false
    end
  end

  def yml_valid?
    begin
      @host_yml_values = YAML.load_file(@host_yml)
      
      valid_keys = ['config','include','exclude','exclude_backup','execute']
      config_valid_subkeys = ['package_base','release_tag','rsync_path','ssh_port','session_mode']
      
      # Begin check for basic elements
      @host_yml_values.each_pair do |key,val|
        if key == 'config' and val.class == Hash
          val.each_pair do |skey,sval|
            unless config_valid_subkeys.include? skey
              puts "Invalid sub-option for 'config:' => #{skey} detected in #{@host_yml}.  Exiting..."
              return false
            end
          end
        else
          unless valid_keys.include? key
            puts "Invalid option => #{key} detected in #{@host_yml}.  Exiting..."
            return false
          end
        end
      end
    rescue Exception => e
      puts "Tried to load #{@host_yml} during 'HostConfig.yml_valid?', received exception: #{e}"
    end
  end

  def host_dir?
    if File.directory? @host_dir
      true
    else
      prepare_host_dir
    end
  end
  
  def hosts_dir?
    if File.directory? @hosts_dir
      true
    else
      prepare_hosts_dir
    end
  end

  def prompt_host_dir
    # This isn't used right now
    print "Configuration directory doesn't exist for #{@host}, create? (N/y): "
    input = gets.chomp
    if input =~ /[yY]/ then true else exit end
  end

  def prepare_host_dir
    begin
      FileUtils.mkdir_p "#{@host_dir}/overrides"
      true
    rescue Exception => e
      puts "Tried to create #{@host_dir} during 'HostConfig.prepare_host_dir', received exception: #{e}"
      false
    end
  end
  
  def prepare_hosts_dir
    begin
      FileUtils.mkdir_p @hosts_dir
      true
    rescue Exception => e
      puts "Tried to create #{@hosts_dir} during 'HostConfig.prepare_hosts_dir', received exception: #{e}"
      false
    end
  end
end
