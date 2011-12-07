module SmoothS3
  class Service
    attr_reader :aws_key, :aws_secret, :ssl, :proxy_service

    def initialize(opts={})
      @aws_key = opts.delete(:aws_key)
      @aws_secret = opts.delete(:aws_secret)

      @ssl = opts.delete(:ssl) == true ? true : false
      @proxy_service = S3::Service.new(:access_key_id => @aws_key, :secret_access_key => @aws_secret, :use_ssl => @ssl)

      test_connection
    end

    def upload(bucket, files, options={})
      Uploader.upload(self, bucket, files, options)
    end

    def upload!(bucket, files, options={})
      Uploader.upload!(self, bucket, files, options)
    end

    def sync_directory(bucket, directory, options={})
      Uploader.sync_directory(self, bucket, directory, options)
    end

    def sync_directory!(bucket, directory, options={})
      Uploader.sync_directory!(self, bucket, directory, options)
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

    # Utility Methods
    def buckets
      @proxy_service.buckets.map { |b| b.name }
    end

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