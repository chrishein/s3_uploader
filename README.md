# S3Uploader

Multithreaded recursive directory uploader to S3 using Fog

## Installation

Add this line to your application's Gemfile:

    gem 's3_uploader'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_uploader

## Usage

	S3Uploader.upload_directory('/tmp/test', 'mybucket', { :destination_dir => 'test/', :threads => 4 })
	
Or as a command line binary

	s3uploader -d test/ -t 4 /tmp/test mybucket

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
