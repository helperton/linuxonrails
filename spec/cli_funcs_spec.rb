require 'cli_funcs.rb'
require 'cli_utils.rb'

describe CliFuncs do
  it "should set environment to development" do
    c = CliFuncs.new
    ENV["RSYNCONRAILS_CONFIG"].should == "development"
  end

  it "should test that base_dir is set" do
    c = CliFuncs.new
    c.base_dir.should_not == nil
  end
  
  it "should test that data_dir is set" do
    c = CliFuncs.new
    c.data_dir.should_not == nil
  end

  it "runs a command with no arguments and captures it's output" do
    u = CliUtils.new("rsync")
    f = CliFuncs.new
    f.ignore_bad_exit = true
    f.run_and_capture(u.utility_path)
    f.output[-1].should =~ /rsync error: syntax or usage error/
  end
  
  it "runs a command with 1 argument and captures it's output" do
    u = CliUtils.new("rsync")
    f = CliFuncs.new
    f.run_and_capture(u.utility_path, "--version")
    f.output[-1].chomp.should == "General Public Licence for details."
  end
end
