require 'spec_helper.rb'
require 'cli_funcs.rb'

describe Rsync do

  it "should verify that the base run flags are correct" do
    r = Rsync.new
    r.flags_run.should == ["-a", "-vv", "-i", "--delete", "--stats"]
  end

  it "should verify that we've added 'dryrun' flag to base flags" do
    r = Rsync.new
    r.flag_dryrun
    r.flags_run.should == ["-a", "-vv", "-i", "--delete", "--stats", "-n"]
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
    r.output_process
    r.uptodate.size.should == 46
    r.deleted.size.should == 0
    r.modified.size.should == 0
    r.created.size.should == 0
    (r.uptodate.size + r.modified.size + r.created.size + r.ignored.size).should == r.transfer_stats['Number of files'].to_i
  end
  
  it "should track changes for a source and dest which are different" do
    r = Rsync.new
    r.flag_dryrun
    r.source = "#{r.datadir}/rsync/testing/source/"
    r.destination = "#{r.datadir}/rsync/testing/source_changes/"
    r.rsync
    r.output_process
    r.uptodate.size.should == 36
    r.deleted.size.should == 7
    r.modified.size.should == 2
    r.created.size.should == 3
    (r.uptodate.size + r.modified.size + r.created.size + r.ignored.size).should == r.transfer_stats["Number of files"].to_i
  end

end
