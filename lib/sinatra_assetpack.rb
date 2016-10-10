require 'sinatra/base'
require 'sinatra/assetpack'

class StaticFleet < Sinatra::Base
  
  set :root, `pwd`.chomp

  register Sinatra::AssetPack

  assets {
    serve '/js',     from: 'client/script'
    serve '/css',    from: 'client/style'
    serve '/images', from: 'client/images'

    # The second parameter defines where the compressed version will be served.
    # (Note: that parameter is optional, AssetPack will figure it out.)
    js :app, '/js/app.js', [
      '/js/**/*.js',
      '/js/**/*.min.js',
      '/js/**/*.coffee',
    ]

    css :application, '/css/application.css', [
      '/css/**/*.css',
      '/css/**/*.sass',
    ]

    js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
    css_compression :simple   # :simple | :sass | :yui | :sqwish
  }
end