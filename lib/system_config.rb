require 'yaml'

SYSTEM_CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/system_config.yml")
