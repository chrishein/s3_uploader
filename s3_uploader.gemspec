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

  gem.add_dependency 'fog-aws'
  gem.add_dependency 'mime-types'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rspec-collection_matchers'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'coveralls'
end
