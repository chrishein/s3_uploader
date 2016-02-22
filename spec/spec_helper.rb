require 'coveralls'
Coveralls.wear!

require 'rspec'
require 'rspec/collection_matchers'
require 's3_uploader'
require 'tmpdir'
require 'open3'

RSpec.configure do |config|
  config.color = true
  config.formatter = 'documentation'
end


def create_test_file(filename, size)
  File.open(filename, 'w') do |f|
    contents = "x" * (1024*1024)
    size.to_i.times { f.write(contents) }
  end
end
