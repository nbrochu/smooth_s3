module SmoothS3
  class Bucket
    
    def self.exists?(bucket, service)
      service.buckets.include? bucket
    end

    def self.file_exists?(file, bucket, service)
      b = service.proxy_service.buckets.find_first(bucket)

      begin
        b.objects.find_first(file)
        return true
      rescue S3::Error::NoSuchKey
        return false
      end
    end

    def self.select(bucket, service)
      Bucket.create(bucket, service) unless Bucket.exists?(bucket, service)
    end

    def self.create(bucket_name, service)
      begin
        new_bucket = service.proxy_service.buckets.build(bucket_name)
        new_bucket.save
      rescue S3::Error::BucketAlreadyExists
        raise SmoothS3::Error, "A bucket named '#{bucket_name}' already exists in the Global S3 Namespace. Please select one of you existing buckets or try a new name."
      end
    end

    def self.store_file(file, remote_file, bucket, service, prefix, overwrite)
      b = service.proxy_service.buckets.find_first(bucket)

      if prefix
        remote_file = prefix + remote_file  if prefix =~ /\/$/
        remote_file = prefix + "/" + remote_file unless prefix =~ /\/$/
      end

      unless overwrite == true
        if Bucket.file_exists?(remote_file, bucket, service)
          puts "'#{remote_file}' already exists on S3 bucket named '#{bucket}'. Use the bang(!) version of the method to overwrite."
          return
        end
      end

      bo = b.objects.build(remote_file)
      bo.content = open(file)
      
      if bo.save
        puts "'#{file}' was uploaded to S3 bucket '#{bucket}' under the name '#{remote_file}'."
      else
        puts "There was a problem trying to upload '#{file}' to S3"
      end
    end

  end
end