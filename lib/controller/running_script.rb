
# A RunningScript instance provides the context available to scripts
#   defined in the web interface.
#
# RunningScript::Page is aliased to Page elsewhere.
#
# The @data instance variable is available to subsequently run scripts.
#   It can be considered the 'return value' of the script and its value will be
#   displayed on the web page.
#
class RunningScript
    
  attr_accessor :data
  
  def initialize(data=nil)
    @data = data
  end
  
  # Representing a new page in a static site
  class Page

    attr_reader :name, :content, :tags

    # ---------------
    # Page#initialize
    # ---------------
    #
    # @param name [String] the name of the new page, i.e. 'my_page'
    #
    # @param content [String] a markdown string
    #
    # @param tags [Array] a list of strings
    #
    def initialize(name=nil, content=nil, tags=nil)
      @name, @content, @tags = name, content, tags
    end
    
    # Class method which saves Page instances as files in a spcified static site.
    # @param pages [Array] of Page instances
    # @param destination [String] the name of the website, i.e. 'my_website'
    def self.save(pages, destination)
      dest_path = File.join("static_sites", destination)
      unless Dir.exists?(dest_path)
        raise(ArgumentError, "#{destination} site doesnt exist")
      end
      markdown_path = File.join(dest_path, "source", "markdown")
      data = pages.to_json.gsub('"', '\"')
      `env STATIC_SEED_PATH=#{markdown_path} ruby lib/static_site_seed.rb #{data}`
    end
  end

end
