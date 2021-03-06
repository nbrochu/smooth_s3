module SmoothS3
  class Bucket
    
    def self.exists?(bucket, service)
      service.refresh.buckets.keys.include? bucket
    end

    def self.file_exists?(file, bucket, service)
      b = service.buckets[bucket]

      begin
        b.objects.find_first(file)
        return true
      rescue
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

      Service.new_buckets[service.aws_key] << new_bucket
    end

    def self.store_file(file, remote_file, bucket, service, options)
      b = service.refresh.buckets[bucket]

      if options[:prefix]
        remote_file = options[:prefix] =~ /\/$/ ? (options[:prefix] + remote_file) : options[:prefix] + "/" + remote_file
      end

      unless options[:overwrite] == true
        if Bucket.file_exists?(remote_file, bucket, service)
          puts "'#{remote_file}' already exists on S3 bucket named '#{bucket}'. Use the bang(!) version of the method to overwrite."
          return
        end
      end

      bo = b.objects.build(remote_file)
      bo.content = open(file)
 
      if Bucket.save_with_retries(3, bo, file)
        puts "'#{file}' was uploaded to S3 bucket '#{bucket}' under the name '#{remote_file}'."
      else
        puts "Impossible to upload '#{file}' to S3 (retries were attempted). Please check file permissions."
      end
    end

    private

      def self.save_with_retries(tries, bucket_object, file)
        done, attempts_left = false, tries

        until done
          break if attempts_left <= 0

          begin
            bucket_object.save
            done = true
          rescue
            puts "There was a problem trying to upload '#{file}' to S3. Retrying..."
          end

          attempts_left -= 1
        end

        done
      end

  end
end