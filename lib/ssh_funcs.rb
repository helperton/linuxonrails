require 'system_config'
require 'net/ssh'

class SSHFuncs
  attr_reader :output
  attr_accessor :hostname, :remote_cmd

  def initialize(hostname)
    @hostname = hostname
    @output
    @run_cmd
    @channel
    open_channel
  end

  def open_channel
    begin
      @channel = Net::SSH.start(@hostname, 'root', :password => "rancor")
    rescue Exception => e
      puts "Couldn't establish SSH session with #{@hostname}, received exception: #{e}"
    end
  end

  def run_cmd(cmd)
    # capture all stderr and stdout output from a remote process
    @output = @channel.exec!(cmd)
    puts "OUTPUT: #{@output}" if DEBUG
  end
end
