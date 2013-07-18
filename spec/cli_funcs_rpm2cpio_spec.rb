require 'spec_helper.rb'
require 'cli_funcs_rpm2cpio.rb'
require 'digest'

describe Rpm2Cpio do

  it "should convert an rpm into cpio binary data" do
    r = Rpm2Cpio.new
    r.rpm_file = "testfiles/libcom_err-1.41.12-14.el6_4.2.x86_64.rpm"
    r.rpm2cpio
    digest = Digest::MD5.hexdigest r.output.to_s
    digest.should == "65e970823fd7c819d3706ae66a704bd3"
  end
  
end
