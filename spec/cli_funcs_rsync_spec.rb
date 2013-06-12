require 'cli_funcs.rb'

describe Rsync do

  it "should verify that the base run flags are correct" do
    r = Rsync.new
    r.flags_run.should == "-a -vv -i --delete"
  end

  it "should verify that we've added 'dryrun' flag to base flags" do
    r = Rsync.new
    r.flag_add(r.flag_dryrun)
    r.flags_run.should == "-a -vv -i --delete -n"
  end
  
  it "should track changes for a source and dest which aren't different" do
    r = Rsync.new
    puts r.basedir
    r.flag_add(r.flag_dryrun)
    r.rsync("#{r.datadir}/source","#{r.datadir}/source_nochanges")
    r.uptodate.should == 30
    r.deleted.should == 0
    r.modified.should == 0
  end

end
