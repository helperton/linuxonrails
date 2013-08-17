require 'spec_helper.rb'
require 'cli_funcs_rpm2cpio.rb'
require 'cli_funcs_cpio.rb'

describe Cpio do

  it "should take binary data and un-cpio to test dir" do
    r = Rpm2Cpio.new
    r.rpm_file = "testfiles/libcom_err-1.41.12-14.el6_4.2.x86_64.rpm"
    r.rpm2cpio
    c = Cpio.new
    c.cpio_data = r.output
    c.extract_dir = "#{c.data_dir}/cpio"
    c.cpio_extract
    File.exist?("#{c.data_dir}/cpio/usr/share/doc/libcom_err-1.41.12/COPYING").should be_true
    File.exist?("#{c.data_dir}/cpio/lib64/libcom_err.so.2").should be_true
    File.exist?("#{c.data_dir}/cpio/lib64/libcom_err.so.2.1").should be_true
  end
  
  it "should take binary data and return a list of files" do
    r = Rpm2Cpio.new
    r.rpm_file = "testfiles/libcom_err-1.41.12-14.el6_4.2.x86_64.rpm"
    r.rpm2cpio
    c = Cpio.new
    c.cpio_data = r.output
    c.cpio_list
    c.file_list[0].should == "./lib64/libcom_err.so.2"
    c.file_list[1].should == "./lib64/libcom_err.so.2.1"
    c.file_list[2].should == "./usr/share/doc/libcom_err-1.41.12"
    c.file_list[3].should == "./usr/share/doc/libcom_err-1.41.12/COPYING"
  end
  
end
