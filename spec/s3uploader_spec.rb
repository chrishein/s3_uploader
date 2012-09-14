require 'spec_helper'

describe S3Uploader do  
    
    it "should upload all files in a directory" do
      pending 'Write real test'
      S3Uploader.upload_directory('/tmp/test', 'mybucket', { :destination_dir => 'test/' })
    end
end