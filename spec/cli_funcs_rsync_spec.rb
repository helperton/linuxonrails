require 'spec_helper.rb'
require 'cli_funcs_rsync.rb'
require 'ssh_funcs.rb'

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
      r.source.push("#{r.data_dir}/rsync/testing/source/pkg#{n}/files/")
    end
    r.destination = "localhost:#{r.data_dir}/rsync/testing/source_nochanges/"
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
      r.source.push("#{r.data_dir}/rsync/testing/source/pkg#{n}/files/")
    end
    r.destination = "localhost:#{r.data_dir}/rsync/testing/source_changes/"
    r.flag_exclude("/excluded_file")
    r.flag_exclude("/3/excluded_file")
    r.flag_exclude("/3/excluded_file with space in name")
    r.flag_exclude("/12")
    r.rsync
    r.output_process
    r.uptodate.size.should == 17
    r.deleted.size.should == 5
    r.modified.size.should == 4
    r.created.size.should == 3
    r.excluded.size.should == 4
    (r.uptodate.size + r.modified.size + r.created.size + r.ignored.size + r.duplicates.size).should == r.transfer_stats["Number of files"].to_i
  end

  it "should verify that rsync source ordering is working" do
    # In the test setup, we have 4 directories, number 2 though 5
    # By passing in directory 2 first, it should win over other directories
    # which contain the same file name
    r = Rsync.new
    1.upto(9) do |n|
      r.source.push("#{r.data_dir}/rsync/testing/source_ordering/pkg#{n}/files/")
    end
    r.destination = "localhost:#{r.data_dir}/rsync/testing/destination_ordering/"
    r.rsync
    r.output_process
    r.uptodate.size.should == 0
    r.deleted.size.should == 0
    r.modified.size.should == 0
    r.created.size.should == 29
    r.duplicates.size.should == 11
    (r.uptodate.size + r.deleted.size + r.modified.size + r.created.size + r.ignored.size + r.duplicates.size).should == r.transfer_stats["Number of files"].to_i
    s = SSHFuncs.new("localhost")
    s.run_cmd("cat #{r.data_dir}/rsync/testing/destination_ordering/file_contains_win")
    s.output.chomp.should == "win"
  end


end
