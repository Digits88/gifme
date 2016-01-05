require 'sinatra/base'
require 'sinatra/json'
require 'sprockets'
require 'sprockets-helpers'

class App < Sinatra::Base
  set :sprockets, Sprockets::Environment.new(root)
  set :assets_prefix, '/assets'
  set :digest_assets, false
  set :logging, true

  configure do
    # Setup Sprockets
    sprockets.append_path File.join(root, 'assets', 'css')
    sprockets.append_path File.join(root, 'assets', 'js')
    sprockets.append_path File.join(root, 'assets', 'images')

    # Configure Sprockets::Helpers (if necessary)
    Sprockets::Helpers.configure do |config|
      config.environment = sprockets
      config.prefix      = assets_prefix
      config.digest      = digest_assets
      config.public_path = public_folder

      # Force to debug mode in development mode
      # Debug mode automatically sets
      # expand = true, digest = false, manifest = false
      config.debug       = true if development?
    end
  end

  require "autoprefixer-rails"
  AutoprefixerRails.install(sprockets)

  helpers do
    include Sprockets::Helpers

    # Alternative method for telling Sprockets::Helpers which
    # Sprockets environment to use.
    # def assets_environment
    #   settings.sprockets
    # end
  end

  get '/' do
    erb :index
  end

  get '/random' do
    dir  = settings.public_folder + "/gifs"
    gifs = Dir.foreach(dir).select { |x| File.file?("#{dir}/#{x}") }
    gif  = gifs.sample
    erb :random, :locals => {:gif => gif}
  end

  # Any request that isn't '/' we can probably assume is trying to direct-link an image.
  get '/:file' do
    send_file File.join(settings.public_folder, "gifs", params[:file])
  end

  post '/api/v0/sample' do
    content_type :json
    query = params[:text]
    dir = settings.public_folder + "/gifs"
    gifs = Dir.foreach(dir).select { |x| File.file?("#{dir}/#{x}") }
    gif = gifs.select{ |i| i[/#{query}/] }
    gif = gif.sample
    puts gif

    if gif != nil
      response = "<https://gif.daneden.me/" + gif + ">"
      json(
        "response_type": "in_channel",
        "text": response,
        "unfurl_links": true,
        "unfurl_media": true
      )
    else
      json(
        "response_type": "ephemeral",
        "text": "Ugh. There weren't any gifs matching that search. My bad. \nYou could always go to <gif.daneden.me> and look for one yourself."
      )
    end

  end

end
