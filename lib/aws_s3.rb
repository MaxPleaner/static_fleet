
# An instance of the aws s3 sdk class
AWS_S3 = Aws::S3::Client.new

# custom helper methods to interact with AWS S3
class AWS_Helpers
  def self.create_bucket(bucketname)
    bucketname = sanitize_bucketname(bucketname)
    bucket = AWS_S3.create_bucket(
      bucket: bucketname,
      acl: "public-read",
      create_bucket_configuration: {
        location_constraint: ENV["AWS_REGION"]
      }
    )
    bucket
  end

  def self.delete_bucket(bucketname)
    bucketname = sanitize_bucketname(bucketname)
    Aws::S3::Bucket.new(bucketname).delete!
    nil
  end

  # An instance of the 'fog' aws helper class
  Storage = Fog::Storage.new({
    :provider   => 'AWS',
    :aws_access_key_id => ENV["AWS_ACCESS_KEY_ID"],
    :aws_secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"],
    :region => ENV["AWS_REGION"]
  })
  
  # uses 'fog' to configure a bucket to be served as a static website
  #
  # @param bucketname [String] is the same as the sitename used to create the site
  # @return [Nil]
  def self.serve_bucket_as_static_website(bucketname)
    bucketname = sanitize_bucketname(bucketname)
    Storage.put_bucket_website(bucketname, "index.html", :key => "404.html")
    nil
  end
  
  # uploads a predefined policy to the bucket
  # this permits global read-access to the files
  #
  # uses the 'fog' aws helper library
  #
  # @param sitename [String]
  # @return [Nil]
  def self.set_bucket_policy(sitename)
    sitename = sanitize_bucketname(sitename)
    policy = {
    	"Version": "2012-10-17",
    	"Statement": [
    		{
    			"Sid": "PublicReadForGetBucketObjects",
    			"Effect": "Allow",
    			"Principal": "*",
    			"Action": "s3:GetObject",
    			"Resource": "arn:aws:s3:::#{sitename}/*"
    		}
    	]
    }
    AWS_S3.put_bucket_policy({
      bucket: sitename,
      policy: policy.to_json
    })
    nil
  end
 
  # works differently depending on whether the site was generated with the static framework
  # tests for this by looking for a know file that probably won't be present in other directories.
  #
  # in the case of the static framework, runs gen.rb to compile source/ to dist/
  #
  # otherwise, copies source/ to dist/ as-is
  #
  # @param sitename [String]
  # @return [Nil]
  def self.build_site(sitename)
    sitepath = File.join("static_sites", sitename)
    static_framework_checksum_path = File.join(sitepath, "STATIC_FRAMEWORK_CHECKSUM")
    is_a_site_generated_by_the_static_framework = File.exists?(static_framework_checksum_path) &&\
      File.read(static_framework_checksum_path).chomp.strip.eql?(ENV["STATIC_FRAMEWORK_CHECKSUM"])
    if is_a_site_generated_by_the_static_framework
      build_static_framework_site(sitepath)
    else
      build_generic_framework_site(sitepath)
    end
    nil
  end
  
  # runs 'aws s3 sync' to upload the dist/ folder
  #
  # @param sitename [String]
  # @return [Nil]
  def self.deploy_site(sitename)
    raise(ArgumentError, 'missing dist folder; run build first') unless \
      Dir.exists?("./static_sites/#{sitename}/dist")
    sitepath = File.join("static_sites", sitename)
    deploy_script = <<-SH
      cd #{sitepath}/dist;
      aws s3 sync . s3://#{sanitize_bucketname(sitename)}
    SH
    system(deploy_script)
    nil
  end
  
  private
  
  # builds a site generated by the static framework
  #
  # @param sitename [String]
  # @return [Nil]
  def self.build_static_framework_site(sitepath)
    build_script = <<-SH
      cd #{sitepath};
      ruby gen.rb;
    SH
    system(build_script)
  end
  
  # builds a generic site without precompilation
  #
  # @param sitepath [String]
  # @return [Nil]
  def self.build_generic_framework_site(sitepath)
    build_script = <<-SH
      cd #{sitepath};
      rm -rf dist/;
      cp -r source dist;
    SH
    system(build_script)
  end
  
  # S3 only allows alphaneumerics, numbers, and dashes in bucket names
  def self.sanitize_bucketname(bucketname)
    bucketname.gsub(/[^A-Za-z0-9\-]/, '-')
  end

end
