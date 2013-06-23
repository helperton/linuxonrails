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
    1.upto(9) do |n|
      r.source.push("#{r.datadir}/rsync/testing/source/pkg#{n}/files/")
    end
    r.destination = "#{r.datadir}/rsync/testing/source_nochanges/"
    r.rsync
    r.output_process
    r.uptodate.size.should == 28
    r.deleted.size.should == 0
    r.modified.size.should == 0
    r.created.size.should == 0
    r.duplicates.size.should == 8
    (r.uptodate.size + r.modified.size + r.created.size + r.ignored.size + r.duplicates.size).should == r.transfer_stats['Number of files'].to_i
  end
  
  it "should track changes for a source and dest which are different" do
    r = Rsync.new
    r.flag_dryrun
    1.upto(9) do |n|
      r.source.push("#{r.datadir}/rsync/testing/source/pkg#{n}/files/")
    end
    r.destination = "#{r.datadir}/rsync/testing/source_changes/"
    r.rsync
    r.output_process
    r.uptodate.size.should == 18
    r.deleted.size.should == 5
    r.modified.size.should == 4
    r.created.size.should == 3
    (r.uptodate.size + r.modified.size + r.created.size + r.ignored.size + r.duplicates.size).should == r.transfer_stats["Number of files"].to_i
  end

end
