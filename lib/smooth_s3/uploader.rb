module SmoothS3
  class Uploader

    def self.upload(service, bucket, files, options={})
      options[:overwrite] = false unless options[:overwrite]
      Bucket.select(bucket, service)
      
      valid_files = Uploader.validate_files(files)
      valid_files.each do |vf|
        Bucket.store_file(vf, vf.split("/")[-1], bucket, service, options[:prefix], options[:overwrite])
      end
    end

    def self.upload!(service, bucket, files, options={})
      options.merge!(:overwrite => true)
      Uploader.upload(service, bucket, files, options)
    end

    def self.sync_directory(service, bucket, directory, options={})
      options[:overwrite] = false unless options[:overwrite]
      Bucket.select(bucket, service)

      valid_files = Uploader.validate_files_in_directory(directory)
      valid_files.each do |vf|
        Bucket.store_file(vf[0], vf[1], bucket, service, options[:prefix], options[:overwrite])
      end
    end

    def self.sync_directory!(service, bucket, directory, options={})
      options.merge!(:overwrite => true)
      Uploader.sync_directory(service, bucket, directory, options)
    end

    def self.timestamped_upload(service, bucket, files, options={})
      options[:overwrite] = false unless options[:overwrite]
      Bucket.select(bucket, service)

      if options[:timestamp_type] == :epoch
        timestamp = Time.now.strftime("%s")
      elsif options[:timestamp_type] == :strftime
        if options[:timestamp_format]
          timestamp = Time.now.strftime(options[:timestamp_format])
        else
          timestamp = Uploader.default_timestamp
        end
      else
        timestamp = Uploader.default_timestamp
      end

      valid_files = Uploader.validate_files(files)
      valid_files.each do |vf|
        Bucket.store_file(vf, timestamp + "_" + vf.split("/")[-1], bucket, service, options[:prefix], options[:overwrite])
      end
    end

    def self.timestamped_upload!(service, bucket, files, options={})
      options.merge!(:overwrite => true)
      Uploader.timestamped_upload(service, bucket, files, options)
    end

    def self.timestamped_directory_sync(service, bucket, directory, options={})
      options[:overwrite] = false unless options[:overwrite]
      Bucket.select(bucket, service)

      if options[:timestamp_type] == :epoch
        timestamp = Time.now.strftime("%s")
      elsif options[:timestamp_type] == :strftime
        if options[:timestamp_format]
          timestamp = Time.now.strftime(options[:timestamp_format])
        else
          timestamp = Uploader.default_timestamp
        end
      else
        timestamp = Uploader.default_timestamp
      end

      valid_files = Uploader.validate_files_in_directory(directory)
      valid_files.each do |vf|
        Bucket.store_file(vf[0], timestamp + "_" + vf[1], bucket, service, options[:prefix], options[:overwrite])
      end
    end

    def self.timestamped_directory_sync!(service, bucket, directory, options={})
      options.merge!(:overwrite => true)
      Uploader.timestamped_directory_sync(service, bucket, directory, options)
    end

    private
      
      def self.validate_files(files)
        valid_files = []

        files = [files] if files.class == String
        files.each do |f|
          begin
            file = File.open(f, "r")
            valid_files << f
            file.close
          rescue Errno::ENOENT
            puts "'#{f}' is an invalid file. Skipping."
          end
        end

        valid_files
      end

      def self.validate_files_in_directory(directory)
        valid_files = []

        begin
          Find.find(directory) do |f|
            next if File.directory?(f)

            file_name = directory.split("/")[-1] + "/" + f.gsub(directory + "/", "")
            valid_files << [f, file_name]
          end
        rescue Errno::ENOENT
          raise SmoothS3::Error, "'#{directory}' is not a valid directory."
        end

        valid_files
      end

      def self.default_timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

  end
end