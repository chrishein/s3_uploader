module S3Uploader
  KILO_SIZE = 1024.0
  BLOCK_SIZE = 1024 * 1024
  DEFAULT_THREADS_NUMBER = 5
  DEFAULT_AWS_REGION = 'us-east-1'

  def self.upload(source, bucket, options = {})
     Uploader.new(options).upload(source, bucket)
  end

  def self.upload_directory(source, bucket, options = {})
    self.upload(source, bucket, options)
  end

  class Uploader
    attr_writer :logger

    def initialize(options = {})

      @options = {
        :destination_dir => '',
        :threads => DEFAULT_THREADS_NUMBER,
        :s3_key => ENV['S3_KEY'],
        :s3_secret => ENV['S3_SECRET'],
        :public => false,
        :region => DEFAULT_AWS_REGION,
        :metadata => {},
        :path_style => false,
        :regexp => nil,
        :gzip => false,
        :gzip_working_dir => nil,
        :time_range => Time.at(0)..(Time.now + (60 * 60 * 24)),
        :filter => '**/*'
      }.merge(options)

      @logger = @options[:logger] || Logger.new(STDOUT)

      if @options[:gzip] && @options[:gzip_working_dir].nil?
        raise 'gzip_working_dir required when using gzip'
      end

      if @options[:connection]
        @connection = @options[:connection]
      else
        if @options[:s3_key].nil? || @options[:s3_secret].nil?
          raise "Missing access keys"
        end

        @connection = Fog::Storage.new({
            :provider => 'AWS',
            :aws_access_key_id => @options[:s3_key],
            :aws_secret_access_key => @options[:s3_secret],
            :region => @options[:region],
            :path_style => @options[:path_style]
        })
      end

      if !@options[:destination_dir].to_s.empty? &&
          !@options[:destination_dir].end_with?('/')
        @options[:destination_dir] << '/'
      end
    end

    def upload(source_dir, bucket)
      raise 'Source directory is requiered' if source_dir.to_s.empty?
      source = source_dir.dup
      source << '/' unless source.end_with?('/')
      raise 'Source must be a directory' unless File.directory?(source)

      gzip_working_dir = @options[:gzip_working_dir]

      if @options[:gzip] && !gzip_working_dir.to_s.empty?
        gzip_working_dir << '/' unless gzip_working_dir.end_with?('/')

        if gzip_working_dir.start_with?(source)
          raise 'gzip_working_dir may not be located within source-folder'
        end
      end

      total_size = 0
      files = Queue.new
      regexp = @options[:regexp]
      Dir.glob(File.join(source, @options[:filter]))
        .select { |f| !File.directory?(f) }.each do |f|

        if (regexp.nil? || File.basename(f).match(regexp)) &&
            @options[:time_range].cover?(File.mtime(f))
          if @options[:gzip] && File.extname(f) != '.gz'
            dir, base = File.split(f)
            dir       = dir.sub(source, gzip_working_dir)
            gz_file   = File.join(dir, [ base, '.gz' ].join)

            @logger.info("Compressing #{f}")

            FileUtils.mkdir_p(dir)
            Zlib::GzipWriter.open(gz_file) do |gz|
              gz.mtime     = File.mtime(f)
              gz.orig_name = f

              File.open(f, 'rb') do |fi|
                while (block_in = fi.read(BLOCK_SIZE)) do
                  gz.write block_in
                end
              end
            end

            files << gz_file
            total_size += File.size(gz_file)
          else
            files << f
            total_size += File.size(f)
          end
        end
      end

      directory = @connection.directories.new(:key => bucket)

      start = Time.now
      total_files = files.size
      file_number = 0
      @mutex = Mutex.new

      threads = []
      @options[:threads].times do |i|
        threads[i] = Thread.new do

          until files.empty?
            @mutex.synchronize do
              file_number += 1
              Thread.current["file_number"] = file_number
            end
            file = files.pop rescue nil
            if file
              key = file.sub(source, '').sub(gzip_working_dir.to_s, '')
              dest = [ @options[:destination_dir], key ].join
              body = File.open(file)
              @logger.info(["[", Thread.current["file_number"], "/",
                            total_files, "] Uploading ", key,
                            " to s3://#{bucket}/#{dest}" ].join)

              directory.files.create(
                :key    => dest,
                :body   => body,
                :public => @options[:public],
                :metadata => @options[:metadata]
              )
              body.close
            end
          end
        end
      end
      threads.each { |t| t.join }

      finish = Time.now
      elapsed = finish.to_f - start.to_f
      mins, secs = elapsed.divmod 60.0
      @logger.info("Uploaded %d (%.#{0}f KB) in %d:%04.2f" %
                  [total_files, total_size / KILO_SIZE, mins.to_i, secs])
    end
  end
end
