require 'spec_helper'

describe S3Uploader do

  let(:access) do
    %w(access.log access.log.1 access.log.2.gz subdir/access.log subdir/access.log.1 subdir/access.log.2.gz)
  end
  let(:error) do
    %w(error.log error.log.1 error.log.2.gz subdir/error.log subdir/error.log.1 subdir/error.log.2.gz)
  end
  let(:tmp_directory) do
    File.join(Dir.tmpdir, 'test_s3_uploader')
  end
  let(:logger) do
    Logger.new(STDOUT)
  end

  let(:connection) do
    Fog.mock!

    connection = Fog::Storage.new({
      :provider                 => 'AWS',
      :aws_access_key_id        => '11111111111',
      :aws_secret_access_key    => 'XXXXXXXXXXXXXXXXXXXXXXXXXXX'
    })

  end

  before(:each) do
    Fog::Mock.reset

    connection.directories.create(
      :key    => 'mybucket',
      :public => true
    )

    FileUtils.rm_rf(Dir.glob(File.join(tmp_directory, '*')))

    (access + error).each do |file|
      directory, basename = File.split(File.join(tmp_directory, file))
      FileUtils.mkdir_p directory
      create_test_file(File.join(directory, basename), 1)
    end
  end

  it 'when called with missing access keys it should raise an exception' do
    lambda {
      S3Uploader.upload_directory('/tmp', 'mybucket',
                                  { destination_dir: 'test1/',
                                    s3_key:          nil,
                                    s3_secret:       nil })
    }.should raise_error('Missing access keys')
  end

  it 'when called with source not directory it should raise an exception' do
    lambda {
      S3Uploader.upload_directory('/xzzaz1232', 'mybucket')
    }.should raise_error('Source must be a directory')
  end

  it 'should upload all files in a directory' do
    connection.directories.get('mybucket', prefix: 'test1/').files.empty?.should be_true

    S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                { destination_dir: 'test1/',
                                  logger:          logger,
                                  connection:      connection })

    files = connection.directories.get('mybucket', prefix: 'test1/').files
    expect(files).to have((access + error).size).items
    expect(files.map(&:key)).to match_array((access + error).map { |f| File.join('test1/', f) })
  end

  describe 'regexp' do

    it 'should upload specific files' do

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:     logger,
                                    connection: connection,
                                    regexp:     /access/ })

      files = connection.directories.get('mybucket').files
      expect(files).to have(access.size).items
      expect(files.map(&:key)).to match_array(access)
    end

  end

  describe 'gzip' do

    it "should require a gzip working directory" do
      lambda {
        S3Uploader.upload_directory('/tmp', 'mybucket',
                                    { logger:     logger,
                                      connection: connection,
                                      gzip: true })
      }.should raise_error('gzip_working_dir required when using gzip')
    end

    it 'should compress files before upload when needed' do
      working_dir = File.join(Dir.tmpdir, 's3uploader_spec/working_dir')
      FileUtils.mkdir_p working_dir
      FileUtils.rm_rf(Dir.glob(File.join(working_dir, '*')))

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:           logger,
                                    connection:       connection,
                                    regexp:           /error/,
                                    gzip:             true,
                                    gzip_working_dir: working_dir })

      files = connection.directories.get('mybucket').files
      expect(files).to have(error.size).items
      expect(files.map(&:key)).to match_array(error.map { |f| File.extname(f) != '.gz' ? [f, '.gz'].join : f })
    end

    it 'when called with bad gzip_working_dir it should raise an exception' do
      expect {
        S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                    { gzip:             true,
                                      gzip_working_dir: File.join(tmp_directory, 'working_dir') })
      }.to raise_error('gzip_working_dir may not be located within source-folder')

      expect {
        S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                    { logger:           logger,
                                      connection:       connection,
                                      regexp:           /non_matching/,
                                      gzip:             true,
                                      gzip_working_dir: File.join(Dir.tmpdir, 'test_s3_uploader_working_dir') })
      }.to_not raise_error

    end
  end

  describe 'time_range' do

    it 'should not upload any files' do
      file_names = access.map { |f| File.join( tmp_directory, f) }
      yesterday  = Time.now - (60 * 60 * 24)
      File.utime(yesterday, yesterday, *file_names)

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:     logger,
                                    connection: connection,
                                    regexp:     /access/,
                                    time_range: (Time.now - (60 * 60 * 12))..Time.now })

      files = connection.directories.get('mybucket').files
      expect(files).to have(0).items
    end

    it 'should upload files' do
      file_names = access.map { |f| File.join( tmp_directory, f) }
      yesterday  = Time.now - (60 * 60 * 12)
      File.utime(yesterday, yesterday, *file_names)


      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:     logger,
                                    connection: connection,
                                    regexp:     /access/,
                                    time_range: (Time.now - (60 * 60 * 24))..Time.now })

      files = connection.directories.get('mybucket').files
      expect(files).to have(access.size).items
      expect(files.map(&:key)).to match_array(access)
    end

  end

end
