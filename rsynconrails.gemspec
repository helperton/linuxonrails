Gem::Specification.new do |s|
  s.name        = 'rsynconrails'
  s.version     = '0.1.1'
  s.date        = '2013-07-29'
  s.summary     = "rsynconrails"
  s.description = "A gem for the rsynconrails app"
  s.authors     = ["Joshua McClintock"]
  s.email       = 'joshua@gravityedge.com'
  
  s.files       = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})

  s.require_paths = ["lib"]

  s.license     = "GPL-2" 
  s.homepage    = 'https://github.com/helperton/rsynconrails'
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
