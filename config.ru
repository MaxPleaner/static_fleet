require './main.rb'
require 'securerandom'

use Rack::Session::Cookie,
    secret: SecureRandom.urlsafe_base64

Database.connect!
run StaticFleet
