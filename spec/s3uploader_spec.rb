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

  before(:each) do
    Fog.mock!

    FileUtils.rm_rf(Dir.glob(File.join(tmp_directory, '*')))

    (access + error).each do |file|
      directory, basename = File.split(File.join(tmp_directory, file))
      FileUtils.mkdir_p directory
      Open3.popen3("dd if=/dev/zero of=#{directory}/#{basename} count=1024 bs=1024")
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
    connection = double(:connection)
    connection.stub_chain(:directories, :new).and_return(directory = double(:directory))
    directory.stub(:files).and_return(files = double(:files))

    files.should_receive(:create).exactly(12).times

    S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                { destination_dir: 'test1/',
                                  logger:          logger,
                                  connection:      connection })
  end

  describe 'regexp' do

    it 'should upload specific files' do
      connection = double(:connection)
      connection.stub_chain(:directories, :new).and_return(directory = double(:directory))
      directory.stub(:files).and_return(files = double(:files))

      keys = access.dup
      files.should_receive(:create).exactly(6).times do |hash|
        expect(keys).to include(hash[:key])
        keys.delete(hash[:key])
      end

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:     logger,
                                    connection: connection,
                                    regexp:     /access/ })
    end

  end

  describe 'gzip' do

    it 'should upload compressed files' do
      connection = double(:connection)
      connection.stub_chain(:directories, :new).and_return(directory = double(:directory))
      directory.stub(:files).and_return(files = double(:files))

      #expect to upload gz-files only
      keys = error.map { |f| f.sub('.gz', '') }.map { |f| f + '.gz' }
      files.should_receive(:create).exactly(6).times do |hash|
        expect(keys).to include(hash[:key])
        keys.delete(hash[:key])
      end

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:     logger,
                                    connection: connection,
                                    regexp:     /error/,
                                    gzip:       true })
    end

    it 'should use gzip_working_dir correctly' do
      working_dir = File.join(Dir.tmpdir, 's3uploader_spec/working_dir')
      FileUtils.mkdir_p working_dir
      FileUtils.rm_rf(Dir.glob(File.join(working_dir, '*')))

      connection = double(:connection)
      connection.stub_chain(:directories, :new).and_return(directory = double(:directory))
      directory.stub(:files).and_return(files = double(:files))

      #expect to upload gz-files only
      keys = error.map { |f| f.sub('.gz', '') }.map { |f| f + '.gz' }
      files.should_receive(:create).exactly(6).times do |hash|
        expect(keys).to include(hash[:key])
        keys.delete(hash[:key])
      end

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:           logger,
                                    connection:       connection,
                                    regexp:           /error/,
                                    gzip:             true,
                                    gzip_working_dir: working_dir })

      #only compress files which aren't compressed yet
      compressed_files = error.select { |f| File.extname(f) != '.gz' }.map { |f| f + '.gz' }
      working_dir_content = Dir["#{working_dir}/**/*"].map { |f| f.sub(working_dir, '')[1..-1] }

      #expect compressed files within working_directory
      expect(working_dir_content & compressed_files).to match_array(compressed_files)
    end

    it 'when called with bad gzip_working_dir it should raise an exception' do
      expect {
        S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                    { gzip:             true,
                                      gzip_working_dir: File.join(Dir.tmpdir, 'test_s3_uploader/working_dir') })
      }.to raise_error('gzip_working_dir may not be located within source-folder')

      expect {
        S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                    { gzip:             true,
                                      gzip_working_dir: File.join(Dir.tmpdir, 'test_s3_uploader_working_dir') })
      }.to raise_error('gzip_working_dir may not be located within source-folder')
    end

  end

  describe 'time_range' do

    it 'should not upload any files' do
      connection = double(:connection)
      connection.stub_chain(:directories, :new).and_return(directory = double(:directory))
      directory.stub(:files).and_return(files = double(:files))

      file_names = access.map { |f| File.join( tmp_directory, f) }
      yesterday  = Time.now - (60 * 60 * 24)
      File.utime(yesterday, yesterday, *file_names)

      files.should_not_receive(:create)

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:     logger,
                                    connection: connection,
                                    regexp:     /access/,
                                    time_range: (Time.now - (60 * 60 * 12))..Time.now })
    end

    it 'should upload files' do
      connection = double(:connection)
      connection.stub_chain(:directories, :new).and_return(directory = double(:directory))
      directory.stub(:files).and_return(files = double(:files))

      file_names = access.map { |f| File.join( tmp_directory, f) }
      yesterday  = Time.now - (60 * 60 * 12)
      File.utime(yesterday, yesterday, *file_names)

      keys = access.dup
      files.should_receive(:create).exactly(6).times do |hash|
        expect(keys).to include(hash[:key])
        keys.delete(hash[:key])
      end

      S3Uploader.upload_directory(tmp_directory, 'mybucket',
                                  { logger:     logger,
                                    connection: connection,
                                    regexp:     /access/,
                                    time_range: (Time.now - (60 * 60 * 24))..Time.now })
    end

  end

end
