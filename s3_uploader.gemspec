# -*- encoding: utf-8 -*-
require File.expand_path('../lib/s3_uploader/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Christian Hein"]
  gem.email         = ["chrishein@gmail.com"]
  gem.description   = %q{S3 multithreaded directory uploader}
  gem.summary       = %q{S3 multithreaded directory uploader}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "s3_uploader"
  gem.require_paths = ["lib"]
  gem.version       = S3Uploader::VERSION
  gem.license       = 'MIT'
  
  gem.add_dependency 'fog'
  
  gem.add_development_dependency 'rspec', '~>2.14.1'
  gem.add_development_dependency 'rake'
end
