require 'cli_utils.rb'

describe CliUtils do

  it "detects the presence of needed utilities" do
    c = CliUtils.new("rsync")
    c.utility.should == "rsync"
    c.utility_path.should == "/usr/bin/rsync"
    c.valid?.should == true
  end

end

