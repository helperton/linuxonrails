require 'spec_helper.rb'
require 'host_config.rb'

describe HostConfig do
  
  it "verifies that hosts_dir is set" do
    c = HostConfig.new("hostname.tld")
    c.hosts_dir.split("/")[-1].should == "hosts"
  end
  
  it "verifies that host_dir is set" do
    c = HostConfig.new("hostname.tld")
    c.host_dir.split("/")[-1].should == "hostname"
  end

  it "handles a hostname.domain fqdn" do
    c = HostConfig.new("hostname.domain.tld")
    c.hostname.should == "hostname"
    c.domain.should == "domain.tld"
  end
  
  it "handles a hostname.subdomain.domain.tld fqdn" do
    c = HostConfig.new("hostname.subdomain.domain.tld")
    c.hostname.should == "hostname"
    c.domain.should == "subdomain.domain.tld"
  end

  it "validates host directory and yml file" do
    c = HostConfig.new("hostname.domain.tld")
    c.host_valid?.should == true
  end

  it "finds a host, given a hostname" do
    c = HostConfig.new("hostname")
    c.found_host.should == "domain.tld/hostname"
  end

  it "shouldn't find a host, then create one with no domain and validate it" do
    c = HostConfig.new("newhost")
    c.found_host.should == "newhost"
  end
  
  it "shouldn't find a host, then create one with domain and validate it" do
    c = HostConfig.new("newhost.tld")
    c.found_host.should == "tld/newhost"
  end


  #it "has a package base" do
  #  c = HostConfig.new("hostname.domain")
  #  c.packbase = SYSTEM_CONFIG["packbase"]
  #  c.packbase.should == ""
  #end

end
