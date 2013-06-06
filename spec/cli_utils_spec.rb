require 'cli_utils.rb'

describe CliUtils do

  it "detects the presence of needed utilities" do
    @c = CliUtils.new
    @c.utility = "rsync"
    @c.utility.should == "rsync"
    @c.valid?.should == true
  end

end

