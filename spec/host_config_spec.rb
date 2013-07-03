require 'spec_helper.rb'
require 'host_config.rb'

describe HostConfig do
  
  it "verifies that hosts_dir is set" do
    c = HostConfig.new()
    c.find_host
    c.hosts_dir.split("/")[-1].should == "hosts"
  end
  
  it "verifies that host_dir is set" do
    c = HostConfig.new("hostname.already.exists")
    c.find_host
    c.host_dir.split("/")[-1].should == "hostname"
  end

  it "handles a hostname.domain fqdn" do
    c = HostConfig.new("hostname.domain.tld")
    c.find_host
    c.host.should == "hostname"
    c.domain.should == "domain.tld"
  end
  
  it "handles a hostname.subdomain.domain.tld fqdn" do
    c = HostConfig.new("hostname.subdomain.domain.tld")
    c.find_host
    c.host.should == "hostname"
    c.domain.should == "subdomain.domain.tld"
  end

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

  it "should read and verify values from host.yml" do
    c = HostConfig.new("hostname.already.exists")
    c.find_host
    c.host_yml_values["config"]["package_base"].should == "test_dist"
    c.host_yml_values["config"]["release_tag"].should == "current"
    c.host_yml_values["config"]["rsync_path"].should == nil
    c.host_yml_values["config"]["ssh_port"].should == nil
    c.host_yml_values["config"]["session_mode"].should == nil
    c.host_yml_values["include"].should == nil
    c.host_yml_values["exclude"].should == nil
    c.host_yml_values["exclude_backup"].should == nil
    c.host_yml_values["execute"].should == nil
  end

end
