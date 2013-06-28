require 'yaml'

def get_env
  ENV['RSYNCONRAILS_CONFIG'] ||= "development"
end

SYSTEM_CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/system_config.yml")[get_env]
DEBUG = SYSTEM_CONFIG["debug"]
