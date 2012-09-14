require 'spec_helper'

describe S3Uploader do  
    before :all do
      Fog.mock!
      @base_test_directory = '/tmp/test_s3_uploader'
      create_test_files(@base_test_directory, 10)
      create_test_files("#{@base_test_directory}/subdir1", 5)
    end
    
    it "should upload all files in a directory" do
      S3Uploader.upload_directory(@base_test_directory, 'mybucket', { :destination_dir => 'test1/' })
    end
    
    after :all do
      FileUtils.rm @base_test_directory
    end
end

def create_test_files(directory, number_of_files)
  FileUtils.mkdir_p directory
  
  $stdout = File.new( '/dev/null', 'w' )

  number_of_files.times do |i|
    `dd if=/dev/zero of=#{directory}/file#{i}.txt count=1024 bs=1024`
  end
  
  $stdout = STDOUT  
end