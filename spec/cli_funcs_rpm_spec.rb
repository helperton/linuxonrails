require 'spec_helper.rb'
require 'cli_funcs_rpm.rb'

describe Rpm do

  it "should query a package for it's control information" do
    r = Rpm.new
    r.rpm_file = "testfiles/libcom_err-1.41.12-14.el6_4.2.x86_64.rpm"
    r.set_control
    r.control["Name"].should == "libcom_err"
    r.control["Version"].should == "1.41.12"
    r.control["Release"].should == "14.el6_4.2"
    r.control["Install Date"].should == "(not installed)"
    r.control["Group"].should == "Development/Libraries"
    r.control["Size"].should == "59233"
    r.control["Signature"].should == "RSA/SHA1, Tue 25 Jun 2013 02:03:51 AM PDT, Key ID 0946fca2c105b9de"
    r.control["Packager"].should == "CentOS BuildSystem <http://bugs.centos.org>"
    r.control["URL"].should == "http://e2fsprogs.sourceforge.net/"
    r.control["Summary"].should == "Common error description library"
    r.control["Relocations"].should == "(not relocatable)"
    r.control["Vendor"].should == "CentOS"
    r.control["Build Date"].should == "Tue 25 Jun 2013 01:51:13 AM PDT"
    r.control["Build Host"].should == "c6b7.bsys.dev.centos.org"
    r.control["Source RPM"].should == "e2fsprogs-1.41.12-14.el6_4.2.src.rpm"
    r.control["License"].should == "MIT"
    #r.control["Description"].should == ""
  end
  
  it "should query a package for it's dependency information" do
    r = Rpm.new
    r.rpm_file = "testfiles/libcom_err-1.41.12-14.el6_4.2.x86_64.rpm"
    r.set_dependencies
    r.dependencies.should have_key "/sbin/ldconfig"
    r.dependencies.should have_key "ld-linux-x86-64.so.2()(64bit)"
    r.dependencies.should have_key "ld-linux-x86-64.so.2(GLIBC_2.3)(64bit)"
    r.dependencies.should have_key "libc.so.6()(64bit)"
    r.dependencies.should have_key "libc.so.6(GLIBC_2.2.5)(64bit)"
    r.dependencies.should have_key "libc.so.6(GLIBC_2.3.4)(64bit)"
    r.dependencies.should have_key "libc.so.6(GLIBC_2.4)(64bit)"
    r.dependencies.should have_key "libcom_err.so.2()(64bit)"
    r.dependencies.should have_key "libpthread.so.0()(64bit)"
    r.dependencies.should have_key "libpthread.so.0(GLIBC_2.2.5)(64bit)"
    r.dependencies.should have_key "rpmlib(CompressedFileNames)"
    r.dependencies["rpmlib(CompressedFileNames)"].should == "<= 3.0.4-1"
    r.dependencies.should have_key "rpmlib(FileDigests)"
    r.dependencies["rpmlib(FileDigests)"].should == "<= 4.6.0-1"
    r.dependencies.should have_key "rpmlib(PayloadFilesHavePrefix)"
    r.dependencies["rpmlib(PayloadFilesHavePrefix)"].should == "<= 4.0-1"
    r.dependencies.should have_key "rtld(GNU_HASH)"
    r.dependencies.should have_key "rpmlib(PayloadIsXz)"
    r.dependencies["rpmlib(PayloadIsXz)"].should == "<= 5.2-1"
  end
  
  it "should query a package for it's provides information" do
    r = Rpm.new
    r.rpm_file = "testfiles/libcom_err-1.41.12-14.el6_4.2.x86_64.rpm"
    r.set_provides
    r.provides.should have_key "libcom_err.so.2()(64bit)"
    r.provides.should have_key "libcom_err"
    r.provides["libcom_err"].should == "1.41.12-14.el6_4.2"
    r.provides.should have_key "libcom_err(x86-64)"
    r.provides["libcom_err(x86-64)"].should == "1.41.12-14.el6_4.2"
  end
  
  it "should query a package for it's file list information" do
    r = Rpm.new
    r.rpm_file = "testfiles/libcom_err-1.41.12-14.el6_4.2.x86_64.rpm"
    r.set_filelist
    r.filelist.should == ['/lib64/libcom_err.so.2', '/lib64/libcom_err.so.2.1', '/usr/share/doc/libcom_err-1.41.12', '/usr/share/doc/libcom_err-1.41.12/COPYING']
  end
  
  it "should query a package for it's install scripts" do
    r = Rpm.new
    r.rpm_file = "testfiles/postfix-2.6.6-2.2.el6_1.x86_64.rpm"
    r.set_scripts
    r.scripts["preinstall"].should match /# Add user and groups if necessary/
    r.scripts["postinstall"].should match /--slave \/usr\/share\/man\/man5\/aliases.5.gz mta-aliasesman/
    r.scripts["preuninstall"].should match /\/sbin\/chkconfig --del postfix/
    r.scripts["postuninstall"].should match /\/sbin\/service postfix condrestart/
  end

  it "should extract rpm content into specified directory" do
    r = Rpm.new
    r.rpm_file = "testfiles/postfix-2.6.6-2.2.el6_1.x86_64.rpm"
    r.set_info
    r.do_extract
  end

end
