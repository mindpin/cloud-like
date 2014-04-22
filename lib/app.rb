require "bundler"
Bundler.setup(:default)
require "sinatra"
require "sinatra/cookies"
require "sinatra/reloader"
require 'sinatra/assetpack'
require "pry"
require "sinatra"
require 'haml'
require 'sass'
require 'coffee_script'
require 'yui/compressor'
require 'sinatra/json'
require "rest_client"
require 'mongoid'
require "multi_json"
require File.expand_path("../../config/env",__FILE__)

require "./lib/user_store"
require "./lib/like"
require "./lib/auth"

class CloudLike < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  set :views, ["templates"]
  set :root, File.expand_path("../../", __FILE__)
  set :cookie_options, :domain => nil
  register Sinatra::AssetPack

  assets {
    serve '/js', :from => 'assets/javascripts'
    serve '/css', :from => 'assets/stylesheets'

    js :application, "/js/application.js", [
      '/js/jquery-1.11.0.min.js',
      '/js/**/*.js'
    ]

    css :application, "/css/application.css", [
      '/css/**/*.css'
    ]

    css_compression :yui
    js_compression  :uglify
  }

  helpers Sinatra::Cookies

  helpers do
    def current_store
      Auth.current_store(self)
    end

    def res(response)
      @res = response
    end

    def respond_with(&block)
      store = UserStore.find_by(secret: params[:secret])
      return 401 if !store
      res MultiJson.dump({
        key:       params[:key],
        user_id:   store.uid,
        user_name: store.name,
        scope:     params[:scope]
      })
      block.call(store)
      content_type :json
      return @res if !params[:callback]
      content_type :js
      "#{params[:callback]}(#{@res})"
    end
  end

  before do
    headers("Access-Control-Allow-Origin" => "*")
  end

  get "/" do
    redirect to("/login") if !current_store
    haml :index
  end

  get "/login" do
    haml :login
  end

  post "/login" do
    begin
      Auth.new(params[:login], params[:password], self).login!
      200
    rescue
      401
    end
  end

  post "/api/like" do
    respond_with do |store|
      store.likes.find_or_create_by(scope: params[:scope], key: params[:key])
    end
  end

  post "/api/unlike" do
    respond_with do |store|
      store.likes.find_by(scope: params[:scope], key: params[:key]).try(:destroy)
    end
  end

  get "/api/like_count" do
    respond_with do |store|
      count = Like.where(scope: params[:scope], key: params[:key]).count
      res MultiJson.dump({
        scope: params[:scope],
        key: params[:key],
        count: count
      })
    end
  end
end
