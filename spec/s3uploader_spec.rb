require 'spec_helper'

describe S3Uploader do
  
  it 'when called with missing access keys it should raise an exception' do
    lambda {
      S3Uploader.upload_directory('/tmp', 'mybucket',
        { :destination_dir => 'test1/',
          :s3_key => nil,
          :s3_secret => nil
        })
    }.should raise_error('Missing access keys')
  end
  
  it 'when called with source not directory it should raise an exception' do
    lambda {
      S3Uploader.upload_directory('/xzzaz1232', 'mybucket')
    }.should raise_error('Source must be a directory')
  end
  
  
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
    @logger = Logger.new(STDOUT)
  end
  
  it "should upload all files in a directory" do
    puts @tmp_directory
#    @logger.should_receive(:info).exactly(15).times.with(/Uploading/)
#    @logger.should_receive(:info).exactly(1).times.with(/Uploaded/)
    
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
    Open3.popen3("dd if=/dev/zero of=#{directory}/file#{i}.txt count=1024 bs=1024")
  end  
end
