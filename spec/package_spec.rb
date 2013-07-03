require 'spec_helper.rb'
require 'package.rb'

describe Package do
  
  it "verifies that packages_dir is set" do
    p = Package.new()
    p.packages_dir.split("/")[-1].should == "packages"
  end

  it "verifies that package is set when given as argument" do
    p = Package.new("section1/package1")
    p.package.should == "section1/package1"
  end
  
  it "verifies that package is set when set after init" do
    p = Package.new()
    p.package = "section1/package1"
    p.package.should == "section1/package1"
  end

  it "verifies that package_base, package_release_tag, and package_dir are set, based on host.yml" do
    h = Host.new("hostname.already.exists")
    h.find_host
    p = Package.new("section1/package1")
    p.set_properties(h)
    p.package_base.should == "test_dist"
    p.package_release_tag.should == "current"
    p.package_dir.should == "#{p.packages_dir}/test_dist/section1/package1/current"
  end
  
  it "verifies that package is valid" do
    h = Host.new("hostname.already.exists")
    h.find_host
    p = Package.new("section1/package1")
    p.set_properties(h)
    p.package_valid?.should == true
  end
end
