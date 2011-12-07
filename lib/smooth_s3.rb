require 'rubygems'
require 's3'

require 'find'

require './lib/smooth_s3/service.rb'
require './lib/smooth_s3/bucket.rb'
require './lib/smooth_s3/uploader.rb'
require './lib/smooth_s3/error.rb'

module SmoothS3
  VERSION = "0.1.0"
end