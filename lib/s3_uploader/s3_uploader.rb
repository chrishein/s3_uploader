module S3Uploader
  def self.upload_directory(source, bucket, options = {})
    options = {
      :destination_dir => '',
      :threads => 5,
      :s3_key => ENV['S3_KEY'],
      :s3_secret => ENV['S3_SECRET'],
      :public => false,
      :region => 'us-east-1'
    }.merge(options)
    
    log = options[:logger] || Logger.new(STDOUT)
    
    raise 'Source must be a directory' unless File.directory?(source)
    
    if options[:connection]
      connection = options[:connection]
    else
      raise "Missing access keys" if options[:s3_key].nil? or options[:s3_secret].nil?
      
      connection = Fog::Storage.new({
          :provider => 'AWS',
          :aws_access_key_id => options[:s3_key],
          :aws_secret_access_key => options[:s3_secret],
          :region => options[:region]
      })
    end
    
    source = source.chop if source.end_with?('/')
    if options[:destination_dir] != '' and !options[:destination_dir].end_with?('/')
      options[:destination_dir] = "#{options[:destination_dir]}/"
    end
    
    files = Queue.new
    Dir.glob("#{source}/**/*").select{ |f| !File.directory?(f) }.each do |f|
      files << f
    end
    
    directory = connection.directories.new(:key => bucket)
    
    total_files = files.size
    file_number = 0
    @mutex = Mutex.new
    
    threads = []
    options[:threads].times do |i|
      threads[i] = Thread.new {
        
        while not files.empty?
          @mutex.synchronize do
            file_number += 1
          end
          file = files.pop
          key = file.gsub(source, '')[1..-1]
          dest = "#{options[:destination_dir]}#{key}"
          log.info("[#{file_number}/#{total_files}] Uploading #{key} to s3://#{bucket}/#{dest}")
          
          directory.files.create(
            :key    => dest,
            :body   => File.open(file),
            :public => options[:public]
          )
        end 
      }
    end
    threads.each { |t| t.join }
    
  end
end
