# Methods for interacting with static websites
class StaticSite
  
  # @return [Array] of existing site names
  def self.sitenames
    `ls static_sites`.split("\n")
  end
  
  # constructs a SelectedSite from a given sitename
  # @param [Hash] with key [:sitename]
  # @return [Hash] with key [:session][:current_site]
  def self.get_site(options)
    sitename = options[:sitename]
    {
      session: {
        current_site: SelectedSite.new(sitename).to_h,
        selected_dir: nil,
        selected_file: nil
      }
    }
  end
  
  # Determines whether a path is a file or folder
  # @param [Hash] with key [:path]
  # @return [Hash]
  def self.get_file_or_dir(options)
    path = options[:path]
    if File.file?(path)
      result = get_file(path)
    elsif Dir.exists?(path)
      result = get_dir(path)
    end
    result
  end
  
  # update a file with some new content
  # @param [Hash] with keys [:path] and [:text]
  # @return [Hash]
  def self.update_file(options)
    path, text = options.values_at(:path, :text)
    sitename = path.split("static_sites/")[1..-1].join.split("/")[0]
    File.open(path, 'w') { |f| f.write(text) }
    {
      session: {
        current_site: SelectedSite.new(sitename).to_h,
        selected_dir: nil,
        selected_file: nil
      },
      flash: {
        msg: "updated #{path}"
      }
    }
  end
  
  # Create a local static site
  # and configure a S3 bucket to be its host.
  # Does not deploy.
  # @param [Hash] with key [:sitename]
  # @return [Hash]
  def self.create_site(options)
    sitename = options[:sitename]
    dest_path = File.join("static_sites", sitename)
    if Dir.exists?(dest_path)
      msg = "Can't create #{dest_path}; already exists"
    else
      `cp -r static_site_skeleton #{dest_path}`
      AWS_Helpers.create_bucket(sitename)
      AWS_Helpers.set_bucket_policy(sitename)
      AWS_Helpers.serve_bucket_as_static_website(sitename)
      msg = "created #{dest_path} and set up S3 bucket serving it as a static website."
    end
    { flash: { msg: msg } }
  end

  def self.build_site(options)
    sitename = options[:sitename]
    AWS_Helpers.build_site(sitename)
    { flash: {
      msg: "Built site to ./static_sites/#{sitename}/dist/"
    } }
  end


  # Deploys a site's dist/ directory to S3
  # @param options [Hash] with key [:sitename]
  # @return [Hash]
  def self.deploy_site(options)
    sitename = options[:sitename]
    AWS_Helpers.deploy_site(sitename)
    { flash: {
      msg: "Deployed site to http://#{sitename}.s3-website-us-east-1.amazonaws.com/"
    } }
  end
  
  # At mimimum, set these instance variables so the views don't break.
  # @return [Hash]
  def self.default_ivars
    {
      ivars: {
        sites: sitenames
      }
    }
  end
  
  # A static site that has been 'selected' through the web interface.
  class SelectedSite

    attr_reader :files, :rootpath, :sitename
    
    # @param sitename [String] i.e. 'my_sitename'
    def initialize(sitename)
      @sitename = sitename
      @rootpath = "./static_sites/#{@sitename}"
      unless Dir.exists?(@rootpath)
        raise ArgumentError, "#{@sitename} does not exist"
      end
      @files = Dir.glob(File.join(@rootpath, "source", "*"))
    end
    
    # @return [Hash]
    def to_h
      { rootpath: rootpath, files: files, sitename: sitename }
    end
    
  end

  
# -------------------------------------------------------
  private
  
  # Gets the text of a file
  # @param path [String]
  # @return [Hash]
  def self.get_file(path)
    text = File.read(path)
    {
      session: {
        selected_file: {
          path: path,
          text: text
        }
      }
    }
  end
  
  # When a dir is clicked
  # Nullifies the current selected file
  # @param path [String]
  # @return [Hash]
  def self.get_dir(path)
    files = glob_with_navigator(path, "*")
    {
      session: {
        selected_dir: {
          path: path,
          files: files
        },
        selected_file: nil
      }
    }
  end
  
  # By default Dir.glob doesn't include "." and ".."
  # This makes it include those
  # @param path [String]
  # @param glob [String]
  # @return [Array] of paths
  def self.glob_with_navigator(path, glob)
    Dir.glob(File.join(path, glob)) + [".", ".."].map do |ext|
      [path, ext].join("/")
    end
  end
# -------------------------------------------------------


end
