require 'rspec'
require 's3_uploader'
require 'tmpdir'
require 'fog'
require 'open3'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter = 'documentation'
end


def create_test_file(filename, size)
  File.open(filename, 'w') do |f|
    contents = "x" * (1024*1024)
    size.to_i.times { f.write(contents) }
  end
end
