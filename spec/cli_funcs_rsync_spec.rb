require 'spec_helper.rb'
require 'cli_funcs.rb'

describe Rsync do

  it "should verify that the base run flags are correct" do
    r = Rsync.new
    r.flags_run.should == ["-a", "-vv", "-i", "--delete"]
  end

  it "should verify that we've added 'dryrun' flag to base flags" do
    r = Rsync.new
    r.flag_dryrun
    r.flags_run.should == ["-a", "-vv", "-i", "--delete", "-n"]
  end

  it "should verify that source is set correctly" do
    r = Rsync.new
    r.source = "testing"
    r.source.should == "testing"
  end
  
  it "should verify that destination is set correctly" do
    r = Rsync.new
    r.destination = "testing"
    r.destination.should == "testing"
  end
  
  it "should track changes for a source and dest which aren't different" do
    r = Rsync.new
    r.flag_dryrun
    r.source = "#{r.datadir}/rsync/testing/source/"
    r.destination = "#{r.datadir}/rsync/testing/source_nochanges/"
    r.rsync
    r.output.each do |line|
      print line
    end
    r.uptodate.size.should == 30
    r.deleted.should == 0
    r.modified.should == 0
  end

end
