require 'fileutils'
#require 'digest/md5'
module S3Uploader
  KILO_SIZE = 1024.0
  def self.upload_directory(source, bucket, options = {})
    options = {
      :destination_dir => '',
      :delete_source => false ,
      :source_glob => '**/*',
      :threads => 5,
      :s3_key => ENV['S3_KEY'],
      :s3_secret => ENV['S3_SECRET'],
      :public => false,
      :chunk_size => 1,
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

    chunk_size = options[:chunk_size].to_i

    total_size = 0
    files = Queue.new
    Dir.glob("#{source}/#{options[:source_glob]}").select{ |f| !File.directory?(f) }.each do |f|
      files << f
      total_size += File.size(f)
      
    end
    
    directory = connection.directories.new(:key => bucket)
    
    start = Time.now
    total_files = files.size
    file_number = 0
    @mutex = Mutex.new
    
    threads = []
    options[:threads].times do |i|
      threads[i] = Thread.new {
        
        while not files.empty?
          chunk = []
          chunk_size.times do 
            chunk << files.pop
          end
          chunk.compact! # remove trailing nil entries
#          @mutex.synchronize do
#            file_number += chunk.size
#          end
          chunk.each do |file|
            key = file.gsub(source, '')[1..-1]
            dest = "#{options[:destination_dir]}#{key}"
#            log.info("[#{file_number}/#{total_files}] Uploading #{key} to s3://#{bucket}/#{dest}")
            log.info("Uploading #{key} to s3://#{bucket}/#{dest}")

            # would be good to do upload_and_verify similar to how RightAWS::S3Interface.store_object_and_verify does it.
            # e.g. to hand-in the MD5-sum of the file and check proper S3 upload via MD5 in the resulting XML.
            directory.files.create(
                                   :key    => dest,
                                   :body   => File.open(file),
                                   :public => options[:public]
                                   )

            # If the user specifies :delete_source, delete each individual local file after upload completes
            if options[:delete_source]
              log.info("Deleting source file #{file}")
              FileUtils.rm_f(file)
            end
          end # chunk.each
          # if options[:delete_source] , we should also delete top-level directories
        end 
      }
    end
    threads.each { |t| t.join }
    
    finish = Time.now
    elapsed = finish.to_f - start.to_f
    mins, secs = elapsed.divmod 60.0
    log.info("Uploaded %d (%.#{0}f KB) in %d:%04.2f" % [total_files, total_size / KILO_SIZE, mins.to_i, secs])
    
  end
end
