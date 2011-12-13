module SmoothS3
  class Service
    attr_reader :aws_key, :aws_secret, :ssl, :proxy_service
    attr_accessor :buckets

    @@new_buckets = {}

    def initialize(opts={})
      @aws_key = opts.delete(:aws_key)
      @aws_secret = opts.delete(:aws_secret)

      @ssl = opts.delete(:ssl) == true ? true : false
      @proxy_service = S3::Service.new(:access_key_id => @aws_key, :secret_access_key => @aws_secret, :use_ssl => @ssl)

      test_connection

      @buckets = gather_buckets
      @@new_buckets[@aws_key] = []
    end

    def gather_buckets
      service_buckets = {}
      begin
        self.proxy_service.buckets.each { |b| service_buckets.merge!(b.name => b) }
      rescue
        puts "There was an error trying to fetch the service's buckets. Retrying..."
        sleep 1

        self.gather_buckets
      end

      service_buckets
    end

    def refresh
      new_buckets = @@new_buckets[self.aws_key]
      new_buckets.each {|nb| self.buckets[nb.name] = nb}
      
      return self
    end

    def upload(bucket, files, options={})
      Uploader.upload(self, bucket, files, options)
    end

    def upload!(bucket, files, options={})
      Uploader.upload!(self, bucket, files, options)
    end

    def directory_sync(bucket, directory, options={})
      Uploader.directory_sync(self, bucket, directory, options)
    end

    def directory_sync!(bucket, directory, options={})
      Uploader.directory_sync!(self, bucket, directory, options)
    end

    def timestamped_upload(bucket, files, options={})
      Uploader.timestamped_upload(self, bucket, files, options)
    end

    def timestamped_upload!(bucket, files, options={})
      Uploader.timestamped_upload!(self, bucket, files, options)
    end

    def timestamped_directory_sync(bucket, directory, options={})
      Uploader.timestamped_directory_sync(self, bucket, directory, options)
    end

    def timestamped_directory_sync!(bucket, directory, options={})
      Uploader.timestamped_directory_sync!(self, bucket, directory, options)
    end

    # Make @@new_buckets accessible outside of the class
    def self.new_buckets
      @@new_buckets
    end

    def self.new_buckets=(value)
      @@new_buckets = value
    end

    # Preserve backwards compatibility
    alias_method :sync_directory, :directory_sync
    alias_method :sync_directory!, :directory_sync!

    private

      def test_connection
        begin
          @proxy_service.send(:service_request, :get)
        rescue S3::Error::SignatureDoesNotMatch => e
          raise Error, "Invalid AWS Key and/or Secret provided."
        end
      end

  end
end