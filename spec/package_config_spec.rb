require 'spec_helper.rb'
require 'package_config.rb'

describe PackageConfig do
  
  it "verifies that packages_dir is set" do
    p = PackageConfig.new()
    p.packages_dir.split("/")[-1].should == "packages"
  end

  it "verifies that package is set when given as argument" do
    p = PackageConfig.new("section1/package1")
    p.package.should == "section1/package1"
  end
  
  it "verifies that package is set when set after init" do
    p = PackageConfig.new()
    p.package = "section1/package1"
    p.package.should == "section1/package1"
  end

  it "verifies that package_base, package_release_tag, and package_dir are set, based on host.yml" do
    h = HostConfig.new("hostname.already.exists")
    h.find_host
    p = PackageConfig.new("section1/package1")
    p.set_properties(h)
    p.package_base.should == "test_dist"
    p.package_release_tag.should == "current"
    p.package_dir.should == "#{p.packages_dir}/test_dist/section1/package1/current"
  end
  
  it "verifies that package is valid" do
    h = HostConfig.new("hostname.already.exists")
    h.find_host
    p = PackageConfig.new("section1/package1")
    p.set_properties(h)
    p.package_valid?.should == true
  end

=begin

  it "validates host directory and yml file" do
    c = HostConfig.new("hostname.already.exists")
    c.find_host
    c.host_valid?.should == true
  end

  it "finds a host named newly.created.tld" do
    c = HostConfig.new("newly.created.tld")
    c.autocreate = true
    c.find_host
    c.found_host.should == "created.tld/newly"
  end
  
  it "finds a host named hostname" do
    c = HostConfig.new("hostname")
    c.find_host
    c.found_host.should == "already.exists/hostname"
  end
  
  it "finds a host named hostname.already.exists" do
    c = HostConfig.new("hostname.already.exists")
    c.find_host
    c.found_host.should == "already.exists/hostname"
  end

  it "shouldn't find a host, then create one with no domain and validate it" do
    c = HostConfig.new("newhost")
    c.autocreate = true
    c.find_host
    c.found_host.should == "newhost"
  end
  
  it "shouldn't find a host, then create one with domain and validate it" do
    c = HostConfig.new("newhost.tld")
    c.autocreate = true
    c.find_host
    c.found_host.should == "tld/newhost"
  end
  
  it "shouldn't find a host" do
    c = HostConfig.new("does.not.exist")
    c.find_host
    c.found_host.should == ""
  end


  #it "has a package base" do
  #  c = HostConfig.new("hostname.domain")
  #  c.packbase = SYSTEM_CONFIG["packbase"]
  #  c.packbase.should == ""
  #end

=end

end
