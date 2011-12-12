module SmoothS3
  class Uploader

    def self.upload(service, bucket, files, options={})
      [:overwrite, :timestamped].each {|s| options[s] = false unless options[s]}
      Bucket.select(bucket, service)
      
      valid_files = Uploader.validate_files(files)
      valid_files.each do |vf|
        remote_file_name = options[:timestamped] ? (options[:timestamp] + "_" + vf.split("/")[-1]) : vf.split("/")[-1]
        Bucket.store_file(vf, remote_file_name, bucket, service, options[:prefix], options[:overwrite])
      end
    end

    def self.upload!(service, bucket, files, options={})
      Uploader.upload(service, bucket, files, options.merge!(:overwrite => true))
    end

    def self.sync_directory(service, bucket, directory, options={})
      [:overwrite, :timestamped].each {|s| options[s] = false unless options[s]}
      Bucket.select(bucket, service)

      valid_files = Uploader.validate_files_in_directory(directory)
      valid_files.each do |vf|
        remote_file_name = options[:timestamped] ? (options[:timestamp] + "_" + vf[1]) : vf[1]
        Bucket.store_file(vf[0], remote_file_name, bucket, service, options[:prefix], options[:overwrite])
      end
    end

    def self.sync_directory!(service, bucket, directory, options={})
      Uploader.sync_directory(service, bucket, directory, options.merge!(:overwrite => true))
    end

    def self.timestamped_upload(service, bucket, files, options={})
      options[:overwrite] = false unless options[:overwrite]
      
      timestamp = Uploader.calculate_timestamp(options)
      Uploader.upload(service, bucket, files, options.merge!(:timestamped => true, :timestamp => timestamp))
    end

    def self.timestamped_upload!(service, bucket, files, options={})
      Uploader.timestamped_upload(service, bucket, files, options.merge!(:overwrite => true))
    end

    def self.timestamped_directory_sync(service, bucket, directory, options={})
      options[:overwrite] = false unless options[:overwrite]

      timestamp = Uploader.calculate_timestamp(options)
      Uploader.sync_directory(service, bucket, directory, options.merge!(:timestamped => true, :timestamp => timestamp))
    end

    def self.timestamped_directory_sync!(service, bucket, directory, options={})
      Uploader.timestamped_directory_sync(service, bucket, directory, options.merge!(:overwrite => true))
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

      def self.calculate_timestamp(options)
        timestamp = nil

        if options[:timestamp_type] == :epoch
          timestamp = Time.now.strftime("%s")
        elsif options[:timestamp_type] == :strftime && options[:timestamp_format]
          timestamp = Time.now.strftime(options[:timestamp_format])
        end

        timestamp || Uploader.default_timestamp
      end

      def self.default_timestamp
        Time.now.strftime("%Y%m%d%H%M%S")
      end

  end
end