require 'system_config'
require 'net/ssh'

class SSHFuncs
  attr_reader :output
  attr_accessor :hostname, :remote_cmd

  def initialize(hostname)
    @hostname = hostname
    @output
    @run_cmd
    @ssh
    ssh_channel
  end

  def ssh_channel
    begin
      @ssh = Net::SSH.start(@hostname, 'root')
    rescue Exception => e
      puts "Couldn't establish SSH session with #{@hostname}, received exception: #{e}"
    end
  end

  def run_cmd(cmd)
    # capture all stderr and stdout output from a remote process
    @output = @ssh.exec!(cmd)
    puts "SSH CMD OUTPUT: #{@output}" if DEBUG
  end
end
