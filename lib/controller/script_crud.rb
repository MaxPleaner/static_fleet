# Methods called by CommandRunner after it has determined the correct command
class ScriptCrud

  # Alias RunningScript::Page to Page to make it easier to type
  Page = RunningScript::Page
  
  # The 'index' method for scripts
  # Groups results by 'category' attribute
  # @param [Hash] (optional) with signature:
  #   limit: integer
  #   start: integer
  # @return [Hash]
  def self.list_scripts(options={})
    limit, start = options.values_at('limit', 'start')
    group_into_categories(
      Pagination.paginate(SavedScript.all, limit, start)
    )
  end
  
  # @return [Hash]
  def self.show_script(options)
    script = SavedScript.find_by(id: options[:id])
    { ivars: { script: script }.merge(script_lists) }
  end
  
  # @param options [Hash] with signature:
  #   name: string,
  #   category: string,
  #   content: string
  # @return [Hash]
  def self.create_script(options)
    name, category, content = options.values_at(:name, :category, :content)
    script = SavedScript.create(name: name, category: category, content: content)
    if script.valid?
      {
        ivars: { script: script }.merge(script_lists),
        flash: { msg: "script created" }
      }
    else
      error_out(script.errors.full_messages)
    end
  end
  
  # @return [Hash]
  def self.delete_script(options)
    id = options[:id]
    script = SavedScript.find_by(id: id)
    script&.destroy
    { ivars: script_lists }
  end
  
  # @return [Hash]
  def self.update_script(options)
    id, name, content = options.values_at(:id, :name, :content)
    script = SavedScript.find_by(id: id)
    script.update(name: name, content: content)
    { ivars: { script: script }.merge(script_lists) }
  end
  
  # @param options [Hash] with signature:
  #   id: an existing script's id
  #   session_data: the current value of session[:data]
  # @return [Hash]
  def self.run_script(options)
    id, session_data = options.values_at(:id, :session_data)
    script = SavedScript.find_by(id: id)
    result = with_default_timeout do
      safely_run_script(script.content, session_data)
    end
    {
      ivars: { script: script }.merge(script_lists),
      session: result.merge(last_run_script: script)
    }
  end
  
  # Get a site.
  # Merges default script ivars with result of StaticSite.get_site
  # @return [Hash]
  def self.get_site(options)
    StaticSite.get_site(options).deep_merge(default_ivars)
  end
  
  # Create a site.
  # Merges default script ivars with result of StaticSite.get_site
  # @return [Hash]
  def self.create_site(options)
    StaticSite.create_site(options).deep_merge(default_ivars).merge(null_current_site)
  end
  
  # When a file/dir in the site directory is clicked
  # Merges default script ivars with result of StaticSite.get_site
  # @return [Hash]
  def self.get_file_or_dir(options)
    StaticSite.get_file_or_dir(options).deep_merge(default_ivars)
  end
  
  # When a file is edited from the web interface
  # Merges default script ivars with result of StaticSite.get_site
  # @param options [Hash] with keys :path and :text
  # @return [Hash]
  def self.update_file(options)
    StaticSite.update_file(options).deep_merge(default_ivars)
  end
  
  def self.deploy_site(options)
    StaticSite.deploy_site(options).deep_merge(default_ivars)
  end
  
  def self.build_site(options)
    StaticSite.build_site(options).deep_merge(default_ivars)
  end
  
  def self.add_page(options)
    begin
      path, sitename = options.values_at(:path, :sitename)
      sanitized = sanitize_filename(path)
      return error_out("invalid filename") unless sanitized.eql?(path)
      path = "./static_sites/#{sitename}/source/#{sanitized}"
      script = <<-SH
        FILE=#{path}
        mkdir -p "$(dirname "$FILE")" && touch "$FILE"
      SH
      system(script)
      {
        flash: { msg: "created #{path}" },
        session: { current_site: StaticSite::SelectedSite.new(sitename).to_h }
      }.merge(default_ivars)
    rescue StandardError => e
      error_out("#{e}, #{e.message}")
    end
  end
  
  def self.remove_page(options)
    begin
      path, sitename = options.values_at(:path, :sitename)
      sanitized = sanitize_filename(path)
      return error_out("invalid filename") unless sanitized.eql?(path)
      path = "./static_sites/#{sitename}/source/#{sanitized}"
      script = <<-SH
        rm -rf #{path}
      SH
      system(script)
      {
        flash: { msg: "removed #{path}" },
        session: {
          current_site: StaticSite::SelectedSite.new(sitename).to_h,
          selected_dir: nil,
          selected_file: nil
        }
      }.merge(default_ivars)
    rescue StandardError => e
      error_out("#{e}, #{e.message}")
    end
  end

  # Builds an empty directory in static_sites/
  # and sets up a bucket on S3
  #
  # @param options [Hash] with [:sitename] key
  # @return [Hash]
  def self.build_empty_site(options)
    sitename = options[:sitename]
    path = "./static_sites/#{sitename}"
    if sitename && !(Dir.exists?(path))
      `mkdir -p #{path}/source`
      AWS_Helpers.create_bucket(sitename)
      AWS_Helpers.set_bucket_policy(sitename)
      AWS_Helpers.serve_bucket_as_static_website(sitename)
      {
        flash: { msg: "Built #{sitename} directory and configured S3 bucket"}
      }.merge(default_ivars).merge(null_current_site)
    else
      { flash: { msg: "Name already taken" } }.merge(default_ivars).merge(null_current_site)
    end
  end
  
  def self.build_empty_site_with_genrb(options)
    sitename = options[:sitename]
    path = "./static_sites/#{sitename}"
    if sitename && !(Dir.exists?(path))
      `mkdir -p #{path}/source`
      `cp static_site_skeleton/gen.rb #{path}`
      `cp static_site_skeleton/helpers.rb #{path}`
      `cp static_site_skeleton/STATIC_FRAMEWORK_CHECKSUM #{path}`
      AWS_Helpers.create_bucket(sitename)
      AWS_Helpers.set_bucket_policy(sitename)
      AWS_Helpers.serve_bucket_as_static_website(sitename)
      {
        flash: { msg: "Built #{sitename} directory and configured S3 bucket" }
      }.merge(default_ivars).merge(null_current_site)
    else
      { flash: { msg: "Name already taken" } }.merge(default_ivar).merge(null_current_site)
    end
  end

  def self.delete_site(options)
    bucketname = options[:sitename]
    begin
      `rm -rf ./static_sites/#{sanitize_filename(bucketname)}`
      begin
        AWS_Helpers.delete_bucket(bucketname)
        msg = "deleted #{bucketname} from filesystem and s3"
      rescue StandardError => e
        msg = "ERROR: #{e}. Deleted from filesystem anyway"
      end
    rescue StandardError => e
      msg = "there was an error removing the folder from the filesystem: #{e}"
    end
    { flash: { msg: msg } }.merge(default_ivars).merge(null_current_site)
  end

# ---------------------------------------------------------------------
  private

  # session variables to indicate that no site is selected anymore
  # @return [Hash]
  def self.null_current_site
    { session: { current_site: nil, selected_file: nil, selected_dir: nil } }
  end
  
  # @param filename [String]
  # @return [String]
  def self.sanitize_filename(filename)
    filename.strip do |name|
     # NOTE: File.basename doesn't work right with Windows paths on Unix
     # get only the filename, not the whole path
     name.gsub!(/^.*(\\|\/)/, '')
  
     # Strip out non-accepted characters
     name.gsub!(/[^0-9A-Za-z.\-]/, '-')
    end
  end
  
  # @param blk [Proc] the block to call in the default time frame
  # @return [Object] the result of the block
  def self.with_default_timeout(&blk)
    with_timeout(15) { blk.call }
  end
  
  # @param seconds [Integer] number of second to wait
  # @param blk [Proc] block to run with specified timeout
  # @return [Object] block result
  def self.with_timeout(seconds, &blk)
    Timeout::timeout(seconds) { blk.call }
  end
  
  # run a script and rescue the errors
  # @param text [String] a ruby command which will be called via eval
  # @param session_data [Object] arbitrary object, optional
  #   The data object is persisted to session.
  #   Any existing value is passed to RunningScript's initialize
  # @return [Hash] with signature:
  #   data: whatever @data was defined as by the command string
  def self.safely_run_script(text, session_data)
    return "Content is empty" if text.blank?
    begin
      running_script = RunningScript.new(session_data)
      running_script.instance_exec { eval(text) }
      data = running_script.data
    rescue StandardError => e
      # the backtrace isn't included here, as it's pretty useless for this situation
      data = "#{e}<br>#{e.message}"
    end
    { data: data }
  end
  
  # The default selection of scripts
  # @return [Hash] a hash signature:
  #   arbitrary_scripts: Array
  #   page_scripts: Array
  #   data_scripts: Array
  def self.script_lists
    default_ivars[:ivars]
  end
  
  # Group a list of scripts by category
  # Looks for a few pre-determined categories only
  # @param [ActiveRecord::Query]
  # @return [Hash]
  def self.group_into_categories(query)
    {
      ivars: {
        arbitrary_scripts: query.where(category: "arbitrary"),
        data_scripts: query.where(category: "data"),
        page_scripts: query.where(category: "page")
      }
    }
  end
  
  # Handle an error (without raising one)
  # Sets the flash[:msg] to an error message
  # Sets the default instance variables
  # @param message [String]
  # @return [Hash]
  def self.error_out(message)
    { flash: { msg: message } }.merge(default_ivars)
  end
  
  # @return [Hash]
  def self.default_ivars
    group_into_categories(SavedScript.all)
  end

# ---------------------------------------------------------------------

end
