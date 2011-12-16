$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'rubygems'
require 's3'

require 'find'

require 'smooth_s3/service.rb'
require 'smooth_s3/bucket.rb'
require 'smooth_s3/uploader.rb'
require 'smooth_s3/error.rb'

module SmoothS3
  VERSION = "0.2.1"
end
