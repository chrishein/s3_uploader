
# DO NOT USE AS IS 
This is a fork of the original project and was used for experimentation only.

--------

# S3Uploader

Multithreaded recursive directory uploader to S3 using [fog](https://github.com/fog/fog).

It recursively transverses all contents of the directory provided as source parameter, uploading all files to the destination bucket.
A destination folder where to put the uploaded files tree inside the bucket can be specified too.

By default, it uses 5 threads to upload files in parallel, but the number can be configured as well.

Files are stored as non public if not otherwise specified.

A CLI binary is included.

## Installation

Add this line to your application's Gemfile:

    gem 's3_uploader'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_uploader

## Usage

	S3Uploader.upload_directory('/tmp/test', 'mybucket',
		{ 	:s3_key => YOUR_KEY,
			:s3_secret => YOUR_SECRET_KEY,
			:destination_dir => 'test/',
			:region => 'eu-west-1',
                        :source_glob => '**/*.tar.gz',   # default: "**/*"
                        :delete_source => false ,        # default: false
			:threads => 4 })

If no keys are provided, it uses S3_KEY and S3_SECRET environment variables. us-east-1 is the default region.

	S3Uploader.upload_directory('/tmp/test', 'mybucket', { :destination_dir => 'test/', :threads => 4 })
	
Or as a command line binary
	
	s3uploader -r eu-west-1 -k YOUR_KEY -s YOUR_SECRET_KEY -d test/ -t 4 /tmp/test mybucket
	
Again, it uses S3_KEY and S3_SECRET environment variables if non provided in parameters.
	
	s3uploader -d test/ -t 4 /tmp/test mybucket

## TODO

1. Allow regex pattern matching to select files to upload
2. Add optional time, size and number of files uploaded report at end of process

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
