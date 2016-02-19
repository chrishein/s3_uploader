require 'spec_helper'

describe S3Uploader do

  let(:tmp_directory) do
    File.join(Dir.tmpdir, 'test_s3_uploader')
  end
  let(:access) do
    %w(access.log access.log.1 access.log.2.gz subdir/access.log subdir/access.log.1 subdir/access.log.2.gz) +
    [ File.join('subdirX', tmp_directory, 'somefile-access.txt')]
  end
  let(:error) do
    %w(error.log error.log.1 error.log.2.gz subdir/error.log subdir/error.log.1 subdir/error.log.2.gz)
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
    expect {
      S3Uploader.upload('/tmp', 'mybucket',
                                  { destination_dir: 'test1/',
                                    s3_key:          nil,
                                    s3_secret:       nil })
    }.to raise_error('Missing access keys')
  end

  it 'when called with source not directory it should raise an exception' do
    expect {
      S3Uploader.upload('/xzzaz1232', 'mybucket', {
        s3_key:          '11111111111',
        s3_secret:       'XXXXXXXXXXXXXXXXXXXXXXXXXXX'
        })
    }.to raise_error('Source must be a directory')
  end

  it 'should upload all files in a directory' do
    expect(connection.directories.get('mybucket', prefix: 'test1/').files.empty?).to be true

    S3Uploader.upload(tmp_directory, 'mybucket',
                                { destination_dir: 'test1/',
                                  logger:          logger,
                                  connection:      connection })

    files = connection.directories.get('mybucket', prefix: 'test1/').files
    expect(files).to have((access + error).size).items
    expect(files.map(&:key)).to match_array((access + error).map { |f| File.join('test1/', f) })
  end

  it 'should still support upload_directory static method for backwards compatibility' do
    expect(connection.directories.get('mybucket', prefix: 'test1/').files.empty?).to be true

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

      S3Uploader.upload(tmp_directory, 'mybucket',
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
      expect {
        S3Uploader.upload('/tmp', 'mybucket',
                                    { logger:     logger,
                                      connection: connection,
                                      gzip: true })
      }.to raise_error('gzip_working_dir required when using gzip')
    end

    it 'should compress files before upload when needed' do
      working_dir = File.join(Dir.tmpdir, 's3uploader_spec/working_dir')
      FileUtils.mkdir_p working_dir
      FileUtils.rm_rf(Dir.glob(File.join(working_dir, '*')))

      S3Uploader.upload(tmp_directory, 'mybucket',
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
        S3Uploader.upload(tmp_directory, 'mybucket', {
                                  s3_key:          '11111111111',
                                  s3_secret:       'XXXXXXXXXXXXXXXXXXXXXXXXXXX',
                                  gzip:             true,
                                  gzip_working_dir: File.join(tmp_directory, 'working_dir') })
      }.to raise_error('gzip_working_dir may not be located within source-folder')

      expect {
        S3Uploader.upload(tmp_directory, 'mybucket',
                                    { logger:           logger,
                                      connection:       connection,
                                      regexp:           /non_matching/,
                                      gzip:             true,
                                      gzip_working_dir: File.join(Dir.tmpdir, 'test_s3_uploader_working_dir') })
      }.to_not raise_error

    end

    # Run with: rspec --tag slow
    it 'uploads large files', :slow do
      working_dir = File.join(Dir.tmpdir, 's3uploader_big_file_spec/working_dir')
      big_file_dir = File.join(Dir.tmpdir, 'test_s3_uploader_big_file')
      FileUtils.mkdir_p working_dir
      FileUtils.mkdir_p  big_file_dir
      create_test_file(File.join(big_file_dir, 'test_big_file.dmp'), 2*1024)

      S3Uploader.upload(big_file_dir, 'mybucket',
                                  { logger:          logger,
                                    connection:      connection,
                                    gzip:             true,
                                    gzip_working_dir: working_dir })

      files = connection.directories.get('mybucket').files
      expect(files.map(&:key)).to match_array([ 'test_big_file.dmp.gz' ])

      FileUtils.rm_rf(Dir.glob(File.join(working_dir, '*')))
      FileUtils.rm_rf(Dir.glob(File.join(big_file_dir, '*')))
    end
  end

  describe 'time_range' do

    it 'should not upload any files' do
      file_names = access.map { |f| File.join( tmp_directory, f) }
      yesterday  = Time.now - (60 * 60 * 24)
      File.utime(yesterday, yesterday, *file_names)

      S3Uploader.upload(tmp_directory, 'mybucket',
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


      S3Uploader.upload(tmp_directory, 'mybucket',
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
