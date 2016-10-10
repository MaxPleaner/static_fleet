source "http://rubygems.org"

# ==========================================
# Dependencies of main.rb and descendents
# ==========================================

# Sinatra is a web framework that's light on boilerplate
gem 'sinatra'
# gem 'sinatra', git: 'http://github.com/sinatra/sinatra'

# Session and Flash are implemented through the rack-flash3 gem
gem 'rack-flash3'

# ActiveRecord is an ORM. It handles all DB interaction
gem 'activerecord'

# Slim is a terse way to write Ruby/HTML templates
gem "slim"

# sinatra-assetpack minimizes and concatenates assets (scripts, styles)
# Use my own fork to fix an error
# TODO: stop using this gem; it's unmaintained
gem 'sinatra-assetpack',
   git: 'https://github.com/MaxPleaner/sinatra-assetpack',
   require: 'sinatra/assetpack'

# awesome print helps present data nicely through Kernel#ap and Kernel#ai
gem "awesome_print"

# AWS S3 SDK
gem 'aws-sdk', '~> 2'

# More AWS methods
gem 'fog-aws'
gem 'mime-types' # a dependency

# load env vars from file
gem 'dotenv'

group :development do
  gem "thin"             # Thin is the server used for development
  gem "sqlite3"          # SQLite3 is the database used for development
  gem "pry"              # Pry helps with debugging
  gem "pry-byebug"       # pry-byebug provides 'next' and 'continue' commands to Pry
end

# =========================================
# Dependencies of static_site_generator
# =========================================

# silence annoying warnings
ENV['RUBY_DEP_GEM_SILENCE_WARNINGS'] = '1'

# scraping
gem 'nokogiri'

# preprocessing
gem "slim"
gem "sass"
gem "coffee-script"
gem "therubyracer"
gem "redcarpet"

group :development do
  # guard / livereload
  gem "guard"
  gem "childprocess"
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'rb-inotify'
  gem 'livereload'
end
