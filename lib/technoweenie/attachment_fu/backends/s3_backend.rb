module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module Backends
      # = AWS::S3 Storage Backend
      #
      # Enables use of {Amazon's Simple Storage Service}[http://aws.amazon.com/s3] as a storage mechanism
      #
      # == Requirements
      #
      # Requires the aws-sdk-v1 gem.
      #
      # == Configuration
      #
      # Configuration is done via <tt>#{Rails.root}/config/amazon_s3.yml</tt> and is loaded according to the <tt>#{Rails.env}</tt>.
      # The minimum connection options that you must specify are a bucket name, your access key id and your secret access key.
      # If you don't already have your access keys, all you need to sign up for the S3 service is an account at Amazon.
      # You can sign up for S3 and get access keys by visiting http://aws.amazon.com/s3.
      #
      # If you wish to use Amazon CloudFront to serve the files, you can also specify a distibution domain for the bucket.
      # To read more about CloudFront, visit http://aws.amazon.com/cloudfront
      #
      # Example configuration (#{Rails.root}/config/amazon_s3.yml)
      #
      #   development:
      #     bucket_name: appname_development
      #     access_key_id: <your key>
      #     secret_access_key: <your key>
      #     distribution_domain: XXXX.cloudfront.net
      #
      #   test:
      #     bucket_name: appname_test
      #     access_key_id: <your key>
      #     secret_access_key: <your key>
      #     distribution_domain: XXXX.cloudfront.net
      #
      #   production:
      #     bucket_name: appname
      #     access_key_id: <your key>
      #     secret_access_key: <your key>
      #     distribution_domain: XXXX.cloudfront.net
      #
      # You can change the location of the config path by passing a full path to the :s3_config_path option.
      #
      #   has_attachment :storage => :s3, :s3_config_path => (#{Rails.root} + '/config/s3.yml')
      #
      # === Required configuration parameters
      #
      # * <tt>:access_key_id</tt> - The access key id for your S3 account. Provided by Amazon.
      # * <tt>:secret_access_key</tt> - The secret access key for your S3 account. Provided by Amazon.
      # * <tt>:bucket_name</tt> - A unique bucket name (think of the bucket_name as being like a database name).
      #
      # If any of these required arguments is missing, a MissingAccessKey exception will be raised from AWS::S3.
      #
      # == About bucket names
      #
      # Bucket names have to be globaly unique across the S3 system. And you can only have up to 100 of them,
      # so it's a good idea to think of a bucket as being like a database, hence the correspondance in this
      # implementation to the development, test, and production environments.
      #
      # The number of objects you can store in a bucket is, for all intents and purposes, unlimited.
      #
      # === Optional configuration parameters
      #
      # * <tt>:server</tt> - The server to make requests to. Defaults to <tt>s3.amazonaws.com</tt>.
      # * <tt>:port</tt> - The port to the requests should be made on. Defaults to 80 or 443 if <tt>:use_ssl</tt> is set.
      # * <tt>:use_ssl</tt> - If set to true, <tt>:port</tt> will be implicitly set to 443, unless specified otherwise. Defaults to false.
      # * <tt>:distribution_domain</tt> - The CloudFront distribution domain for the bucket.  This can either be the assigned
      #     distribution domain (ie. XXX.cloudfront.net) or a chosen domain using a CNAME. See CloudFront for more details.
      #
      # == Usage
      #
      # To specify S3 as the storage mechanism for a model, set the acts_as_attachment <tt>:storage</tt> option to <tt>:s3</tt>.
      #
      #   class Photo < ActiveRecord::Base
      #     has_attachment :storage => :s3
      #   end
      #
      # === Customizing the path
      #
      # By default, files are prefixed using a pseudo hierarchy in the form of <tt>:table_name/:id</tt>, which results
      # in S3 urls that look like: http(s)://:server/:bucket_name/:table_name/:id/:filename with :table_name
      # representing the customizable portion of the path. You can customize this prefix using the <tt>:path_prefix</tt>
      # option:
      #
      #   class Photo < ActiveRecord::Base
      #     has_attachment :storage => :s3, :path_prefix => 'my/custom/path'
      #   end
      #
      # Which would result in URLs like <tt>http(s)://:server/:bucket_name/my/custom/path/:id/:filename.</tt>
      #
      # === Using different bucket names on different models
      #
      # By default the bucket name that the file will be stored to is the one specified by the
      # <tt>:bucket_name</tt> key in the amazon_s3.yml file.  You can use the <tt>:bucket_key</tt> option
      # to overide this behavior on a per model basis.  For instance if you want a bucket that will hold
      # only Photos you can do this:
      #
      #   class Photo < ActiveRecord::Base
      #     has_attachment :storage => :s3, :bucket_key => :photo_bucket_name
      #   end
      #
      # And then your amazon_s3.yml file needs to look like this.
      #
      #   development:
      #     bucket_name: appname_development
      #     access_key_id: <your key>
      #     secret_access_key: <your key>
      #
      #   test:
      #     bucket_name: appname_test
      #     access_key_id: <your key>
      #     secret_access_key: <your key>
      #
      #   production:
      #     bucket_name: appname
      #     photo_bucket_name: appname_photos
      #     access_key_id: <your key>
      #     secret_access_key: <your key>
      #
      #  If the bucket_key you specify is not there in a certain environment then attachment_fu will
      #  default to the <tt>bucket_name</tt> key.  This way you only have to create special buckets
      #  this can be helpful if you only need special buckets in certain environments.
      #
      # === Permissions
      #
      # By default, files are stored on S3 with public access permissions. You can customize this using
      # the <tt>:s3_access</tt> option to <tt>has_attachment</tt>. Available values are
      # <tt>:private</tt>, <tt>:public_read_write</tt>, and <tt>:authenticated_read</tt>.
      #
      # === Other options
      #
      # Of course, all the usual configuration options apply, such as content_type and thumbnails:
      #
      #   class Photo < ActiveRecord::Base
      #     has_attachment :storage => :s3, :content_type => ['application/pdf', :image], :resize_to => 'x50'
      #     has_attachment :storage => :s3, :thumbnails => { :thumb => [50, 50], :geometry => 'x50' }
      #   end
      #
      # === Accessing S3 URLs
      #
      # You can get an object's URL using the s3_url accessor. For example, assuming that for your postcard app
      # you had a bucket name like 'postcard_world_development', and an attachment model called Photo:
      #
      #   @postcard.s3_url # => http(s)://s3.amazonaws.com/postcard_world_development/photos/1/mexico.jpg
      #
      # The resulting url is in the form: http(s)://:server/:bucket_name/:table_name/:id/:file.
      # The optional thumbnail argument will output the thumbnail's filename (if any).
      #
      # Additionally, you can get an object's base path relative to the bucket root using
      # <tt>base_path</tt>:
      #
      #   @photo.file_base_path # => photos/1
      #
      # And the full path (including the filename) using <tt>full_filename</tt>:
      #
      #   @photo.full_filename # => photos/
      #
      # Niether <tt>base_path</tt> or <tt>full_filename</tt> include the bucket name as part of the path.
      # You can retrieve the bucket name using the <tt>bucket_name</tt> method.
      #
      # === Accessing CloudFront URLs
      #
      # You can get an object's CloudFront URL using the cloudfront_url accessor.  Using the example from above:
      # @postcard.cloudfront_url # => http://XXXX.cloudfront.net/photos/1/mexico.jpg
      #
      # The resulting url is in the form: http://:distribution_domain/:table_name/:id/:file
      #
      # If you set :cloudfront to true in your model, the public_filename will be the CloudFront
      # URL, not the S3 URL.
      module S3Backend
        class RequiredLibraryNotFoundError < StandardError; end
        class ConfigFileNotFoundError < StandardError; end

        def self.included(base) #:nodoc:
          mattr_reader :bucket_name, :s3_config, :s3_conn, :bucket

          begin
            require 'aws-sdk-v1'
          rescue LoadError
            raise RequiredLibraryNotFoundError.new('aws-sdk-v1 could not be loaded. Make sure the gem is installed.')
          end

          begin
            @@s3_config_path = base.attachment_options[:s3_config_path] || File.join(Rails.root.to_s, 'config', 'amazon_s3.yml')
            @@s3_config = @@s3_config = YAML.load(ERB.new(File.read(@@s3_config_path)).result)[Rails.env].symbolize_keys
          #rescue
          #  raise ConfigFileNotFoundError.new('File %s not found' % @@s3_config_path)
          end

          bucket_key = base.attachment_options[:bucket_key]

          if bucket_key and s3_config[bucket_key.to_sym]
            eval_string = "def bucket_name()\n  \"#{s3_config[bucket_key.to_sym]}\"\nend"
          else
            eval_string = "def bucket_name()\n  \"#{s3_config[:bucket_name]}\"\nend"
          end
          base.class_eval(eval_string, __FILE__, __LINE__)

          @@s3_conn = AWS::S3.new(s3_config.slice(:access_key_id, :secret_access_key))
          @@bucket = s3_conn.buckets[s3_config[:bucket_name]]

          #Base.establish_connection!(s3_config.slice(:access_key_id, :secret_access_key, :server, :port, :use_ssl, :persistent, :proxy))

          base.before_update :rename_file
        end

        def self.protocol
          @protocol ||= s3_config[:use_ssl] ? 'https://' : 'http://'
        end

        def self.hostname
          @hostname ||= s3_config[:server] || 's3.amazonaws.com'
        end

        def self.port_string
          @port_string ||= (s3_config[:port].nil? || s3_config[:port] == (s3_config[:use_ssl] ? 443 : 80)) ? '' : ":#{s3_config[:port]}"
        end

        def self.distribution_domain
          @distribution_domain = s3_config[:distribution_domain]
        end

        module ClassMethods
          def s3_protocol
            Technoweenie::AttachmentFu::Backends::S3Backend.protocol
          end

          def s3_hostname
            Technoweenie::AttachmentFu::Backends::S3Backend.hostname
          end

          def s3_port_string
            Technoweenie::AttachmentFu::Backends::S3Backend.port_string
          end

          def cloudfront_distribution_domain
            Technoweenie::AttachmentFu::Backends::S3Backend.distribution_domain
          end
        end

        # Overwrites the base filename writer in order to store the old filename
        def filename=(value)
          @old_filename = filename unless filename.nil? || @old_filename
          write_attribute :filename, sanitize_filename(value)
        end

        # The attachment ID used in the full path of a file
        def attachment_path_id
          ((respond_to?(:parent_id) && parent_id) || id).to_s
        end

        # The pseudo hierarchy containing the file relative to the bucket name
        # Example: <tt>:table_name/:id</tt>
        def base_path(thumbnail = nil)
          file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:path_prefix]
          File.join(file_system_path, attachment_path_id)
        end

        # The full path to the file relative to the bucket name
        # Example: <tt>:table_name/:id/:filename</tt>
        def full_filename(thumbnail = nil)
          File.join(base_path(thumbnail), thumbnail_name_for(thumbnail))
        end

        # All public objects are accessible via a GET request to the S3 servers. You can generate a
        # url for an object using the s3_url method.
        #
        #   @photo.s3_url
        #
        # The resulting url is in the form: <tt>http(s)://:server/:bucket_name/:table_name/:id/:file</tt> where
        # the <tt>:server</tt> variable defaults to <tt>AWS::S3 URL::DEFAULT_HOST</tt> (s3.amazonaws.com) and can be
        # set using the configuration parameters in <tt>#{Rails.root}/config/amazon_s3.yml</tt>.
        #
        # The optional thumbnail argument will output the thumbnail's filename (if any).
        def s3_url(thumbnail = nil)
          File.join(s3_protocol + s3_hostname + s3_port_string, bucket_name, full_filename(thumbnail))
        end

        # All public objects are accessible via a GET request to CloudFront. You can generate a
        # url for an object using the cloudfront_url method.
        #
        #   @photo.cloudfront_url
        #
        # The resulting url is in the form: <tt>http://:distribution_domain/:table_name/:id/:file</tt> using
        # the <tt>:distribution_domain</tt> variable set in the configuration parameters in <tt>#{Rails.root}/config/amazon_s3.yml</tt>.
        #
        # The optional thumbnail argument will output the thumbnail's filename (if any).
        def cloudfront_url(thumbnail = nil)
          s3_protocol + cloudfront_distribution_domain + "/" + full_filename(thumbnail)
        end

        def public_filename(*args)
          if attachment_options[:cloudfront]
            cloudfront_url(*args)
          else
            s3_url(*args)
          end
        end

        # All private objects are accessible via an authenticated GET request to the S3 servers. You can generate an
        # authenticated url for an object like this:
        #
        #   @photo.authenticated_s3_url
        #
        # By default authenticated urls expire 5 minutes after they were generated.
        #
        # Expiration options can be specified either with an absolute time using the <tt>:expires</tt> option,
        # or with a number of seconds relative to now with the <tt>:expires_in</tt> option:
        #
        #   # Absolute expiration date (October 13th, 2025)
        #   @photo.authenticated_s3_url(:expires => Time.mktime(2025,10,13).to_i)
        #
        #   # Expiration in five hours from now
        #   @photo.authenticated_s3_url(:expires_in => 5.hours)
        #
        # You can specify whether the url should go over SSL with the <tt>:use_ssl</tt> option.
        # By default, the ssl settings for the current connection will be used:
        #
        #   @photo.authenticated_s3_url(:use_ssl => true)
        #
        # Finally, the optional thumbnail argument will output the thumbnail's filename (if any):
        #
        #   @photo.authenticated_s3_url('thumbnail', :expires_in => 5.hours, :use_ssl => true)
        def authenticated_s3_url(*args)
          options   = args.extract_options!
          options[:expires] = options[:expires_in].to_i if options[:expires_in]
          options[:secure] = options[:use_ssl] if options[:use_ssl]
          options.delete(:expires_in) if options[:expires_in]
          options.delete(:use_ssl) if options[:use_ssl]
          thumbnail = args.shift
          bucket.objects[full_filename(thumbnail)].url_for(:read, options).to_s
        end

        def create_temp_file
          write_to_temp_file current_data
        end

        def current_data
          if attachment_options[:encrypted_storage] && self.respond_to?(:encryption_key) && self.encryption_key != nil
            EncryptedData.decrypt_data(bucket.objects[full_filename].read, self.encryption_key)
          else
            bucket.objects[full_filename].read
          end
        end

        def s3_protocol
          Technoweenie::AttachmentFu::Backends::S3Backend.protocol
        end

        def s3_hostname
          Technoweenie::AttachmentFu::Backends::S3Backend.hostname
        end

        def s3_port_string
          Technoweenie::AttachmentFu::Backends::S3Backend.port_string
        end

        def cloudfront_distribution_domain
          Technoweenie::AttachmentFu::Backends::S3Backend.distribution_domain
        end

        protected
          # Called in the after_destroy callback
          def destroy_file
            obj = bucket.objects[full_filename]
            obj.delete
          end

          def rename_file
            return unless @old_filename && @old_filename != filename

            old_full_filename = File.join(base_path, @old_filename)
            old_obj = bucket.objects[old_full_filename]
            obj = bucket.objects[full_filename]

            if attachment_options[:encrypted_storage]
              obj.copy_from(old_obj, {:cache_control => attachment_options[:cache_control],
                                      :acl => attachment_options[:s3_access],
                                      :server_side_encryption => :aes256,
                                      :content_disposition => "attachment; filename=\"#{filename}\""})
            else
              obj.copy_from(old_obj, {:cache_control => attachment_options[:cache_control],
                                      :acl => attachment_options[:s3_access]})
            end

            old_obj.delete
            @old_filename = nil
            true
          end

          def save_to_storage
            if save_attachment?
              if attachment_options[:encrypted_storage]
                obj = bucket.objects[full_filename]
                obj.write(:file => (temp_path ? File.open(temp_path) : temp_data),
                          :cache_control => attachment_options[:cache_control],
                          :acl => attachment_options[:s3_access],
                          :server_side_encryption => :aes256,
                          :content_disposition => "attachment; filename=\"#{filename}\""
                )
              else
                obj = bucket.objects[full_filename]
                obj.write(:file => (temp_path ? File.open(temp_path) : temp_data),
                          :cache_control => attachment_options[:cache_control],
                          :acl => attachment_options[:s3_access]
                )
              end
            end

            @old_filename = nil
            true
          end
      end
    end
  end
end
