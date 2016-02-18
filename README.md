# S3Uploader

[![Gem Version](https://badge.fury.io/rb/s3_uploader.png)](http://badge.fury.io/rb/s3_uploader)
[![Build Status](https://travis-ci.org/chrishein/s3_uploader.svg?branch=master)](https://travis-ci.org/chrishein/s3_uploader)

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

```ruby
	uploader = S3Uploader::Uploader.new({
         :s3_key => YOUR_KEY,
         :s3_secret => YOUR_SECRET_KEY,
         :destination_dir => 'test/',
         :region => 'eu-west-1',
         :threads => 10
		})

  uploader.upload('/tmp/test', 'mybucket')
```

or

```ruby
	S3Uploader.upload('/tmp/test', 'mybucket',
		{ 	 :s3_key => YOUR_KEY,
			   :s3_secret => YOUR_SECRET_KEY,
			   :destination_dir => 'test/',
			   :region => 'eu-west-1',
			   :threads => 4,
			   :metadata => { 'Cache-Control' => 'max-age=315576000' }
		})
```

Former static method upload_directory is still supported for backwards compatibility.

```ruby
	S3Uploader.upload_directory('/tmp/test', 'mybucket', { :destination_dir => 'test/', :threads => 4 })
```

If no keys are provided, it uses S3_KEY and S3_SECRET environment variables. us-east-1 is the default region.

Metadata headers are documented [here](http://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPUT.html)

Or as a command line binary

	s3uploader -r eu-west-1 -k YOUR_KEY -s YOUR_SECRET_KEY -d test/ -t 4 /tmp/test mybucket

Again, it uses S3_KEY and S3_SECRET environment variables if non provided in parameters.

	s3uploader -d test/ -t 4 /tmp/test mybucket

## Compress files

If the `:gzip` options is used, files not already compressed are packed using GZip before upload. A GZip working
directory is required in this case.

```ruby
  S3Uploader.upload_directory('/tmp/test', 'mybucket',
    {    :s3_key => YOUR_KEY,
         :s3_secret => YOUR_SECRET_KEY,
         :destination_dir => 'test/',
         :region => 'eu-west-1',
         :gzip => true,
         :gzip_working_dir => '/tmp/gzip_working_dir'
    })
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

* [Mark Wagner](https://github.com/theSociableme)
* [Brandon Hilkert](https://github.com/brandonhilkert)
* [Philip Cunningham](https://github.com/unsymbol)
* [Ludwig Bratke](https://github.com/bratke)
* [John Pignata](https://github.com/jpignata)
* [eperezks](https://github.com/eperezks)

## License

Distributed under the MIT License. See LICENSE file for further details.
