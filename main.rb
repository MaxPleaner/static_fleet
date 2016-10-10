# Gems
require 'sinatra/base'          # sinatra framework
require 'rack-flash'            # flash & session
require 'active_record'         # ActiveRecord ORM
require 'sqlite3'               # SQL database
require 'active_support/all'    # ActiveSupport ruby utils
require 'slim'                  # Slim HTML templates
require 'pry'                   # Pry debugger
require 'awesome_print'         # console printing utils
require 'nokogiri'              # HTML parsing
require 'dotenv'                # ENV vars
require 'aws-sdk'               # AWS deploy utils
require 'fog/aws'               # AWS deploy utils 2
require 'mime-types'            # \ dependency

# Standard Lib
require 'ostruct'               # OpenStruct
require 'json'                  # JSON

# load env vars from .env
# this is in .gitignore
Dotenv.load

# AWS S3 helpers
require './lib/aws_s3'

# Controller stuff
require "./lib/controller/command_runner"
require './lib/controller/pagination'
require './lib/controller/running_script'
require "./lib/controller/script_crud"
require './lib/controller/sinatra_utils'

# Static Site
require './lib/static_site.rb'

# Database stuff
require './lib/database/database'

# Model stuff
require './lib/model/models'
require "./lib/model/saved_script"

# Asset stuff
require './lib/sinatra_assetpack'

# Define a Sinatra app in the modular style
class StaticFleet < Sinatra::Base
  
  # very basic single-use auth
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username == ENV["STATIC_FLEET_USERNAME"] and \
    password == ENV["STATIC_FLEET_PASSWORD"]
  end

  # Use cookies to persist data between requests
  use Rack::Flash
  
  # @return [Hash]
  def session
    flash['session'] ||= {}
    flash['session']
  end
  
  def set_in_session(key, val)
    flash['session'] ||= {}
    flash['session'][key] = val
  end

  # Keep track of what commands have been run
  State = {}
  
  # Parse params into commands
  include CommandRunner
  
  # Add data to instance variables, flash, and session
  include SinatraUtils

  # Patch the Sinatra run! command to raise an error
  # unless migrations have been run
  def run!(*args)
    if State["DatabaseConnected"]
      super
    else
      raise(
        ArgumentError,
        "run Database.connect! Before StaticFleet.run!"
      )
    end
  end

  # the root route handles all requests except file uploads
  get '/' do
    command = get_command(params)
    result = send_command(command, session[:data])
    result = result.deep_merge(StaticSite.default_ivars)
    copy_object_to_ivars(result[:ivars])
    copy_object_to_flash(result[:flash])
    copy_object_to_session(result[:session])
    slim :root
  end

  # upload a site as a zip file
  post "/upload_generic_site" do
    if (sitename = params[:sitename]) && (file_obj = params['file']) && (!sitename.blank?)
      sitename = sitename.chars.map { |char| char =~ /[A-Za-z1-9\.\-\_]/ ? char : "-" }.join
      file_text = file_obj[:tempfile]&.read
      filename = file_obj[:filename]
      `mkdir ./static_sites/#{sitename}`
      final_dest_path = "./static_sites/#{sitename}/source"
      zip_dest_path = "#{final_dest_path}.zip"
      downloaded_zip_path = "#{zip_dest_path}"
      if [zip_dest_path, downloaded_zip_path].any? { |path| Dir.exists?(path) }
        flash[:msg] = "Site with that name already exists"
      elsif filename.ends_with?(".zip")
        File.open(zip_dest_path, 'w') do |f|
          f.write(file_text)
        end
        unzip_cmd = <<-SH
          unzip #{downloaded_zip_path} -d #{final_dest_path}
          rm #{downloaded_zip_path}
        SH
        system(unzip_cmd)
        AWS_Helpers.create_bucket(sitename)
        AWS_Helpers.set_bucket_policy(sitename)
        AWS_Helpers.serve_bucket_as_static_website(sitename)
        flash[:msg] = "Extracted site into #{final_dest_path}. Created & configured S3 bucket"
        set_in_session(:current_site, StaticSite::SelectedSite.new(sitename).to_h)
        set_in_session(:selected_dir, nil)
        set_in_session(:selected_file, nil)
      else
        flash[:msg] = "provided file was not in .zip format"
      end
    else
      flash[:msg] = ":sitename or :file param missing"
    end
    flash[:session] = flash[:session] # persists it for another request
    redirect to('/?create_site')
  end
  
  # upload a file to the selected site
  post '/upload_file' do
    sitename = params[:sitename]
   if (path = params[:path]) && (sitename = params[:sitename]) && (file_obj = params['file']) && (!sitename.blank?)
      path_parts = path.split("/")
      dir_path = path_parts[0..-2].join("/")
      filename = path_parts[-1]
      sitename, filename, dir_path = [sitename, filename, dir_path].map { |str| str.chars.map { |char| char =~ /[A-Za-z1-9\.\-\_]/ ? char : "-" }.join }
      file_text = file_obj[:tempfile]&.read
      final_dir_path = "./static_sites/#{sitename}/source/#{dir_path}"
      final_file_path = "#{final_dir_path}/#{filename}"
      `mkdir -p #{final_dir_path}`
      File.open("#{final_file_path}", 'w') { |f| f.write(file_text) }
      flash[:msg] = "Uploaded file to #{final_file_path}"
      set_in_session(:current_site, StaticSite::SelectedSite.new(sitename).to_h)
    else
      flash[:msg] = ":sitename or :file param missing"
    end
    flash[:session] = flash[:session] # persists it for another request
    redirect to('/?add_page')
  end
      
end

# Start the server if this file is executed,
# but not if it's loaded through require
if __FILE__ == $0
  Database.connect!
  StaticFleet.run!
end
