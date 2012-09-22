require 'spec_helper'

describe S3Uploader do  
    before :all do
      Fog.mock!
      
      @connection = Fog::Storage.new({
        :provider                 => 'AWS',
        :aws_access_key_id        => '11111111111',
        :aws_secret_access_key    => 'XXXXXXXXXXXXXXXXXXXXXXXXXXX'
      })
      
      @connection.directories.create(
        :key    => 'mybucket',
        :public => true
      )
      
      @tmp_directory = File.join(Dir.tmpdir, 'test_s3_uploader')
      create_test_files(@tmp_directory, 10)
      create_test_files(File.join(@tmp_directory, 'subdir1'), 5)
      @logger = Logger.new(StringIO.new)
    end
    
    it "should upload all files in a directory" do
      
      @logger.should_receive(:info).exactly(15).times.with(/Uploading/)
      
      S3Uploader.upload_directory(@tmp_directory, 'mybucket',
        { :destination_dir => 'test1/',
          :logger => @logger,
          :connection => @connection
        })
      
    end
    
end

def create_test_files(directory, number_of_files)
  FileUtils.mkdir_p directory

  number_of_files.times do |i|
    Open3.popen3('dd if=/dev/zero of=#{directory}/file#{i}.txt count=1024 bs=1024')
  end  
end
