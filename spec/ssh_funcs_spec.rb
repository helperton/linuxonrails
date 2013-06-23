require 'ssh_funcs.rb'

describe SSHFuncs do

  it "opens an ssh channel to localhost and gets hostname output" do
    c = SSHFuncs.new("localhost")
    c.run_cmd("uname")
    c.output.chomp.should == "Linux"
    c.run_cmd("echo \"cool\"")
    c.output.chomp.should == "cool"
  end

end

