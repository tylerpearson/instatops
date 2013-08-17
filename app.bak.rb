require "sinatra"
require "instagram"
require 'pp'

set :session_secret, ENV["SESSION_KEY"] || 'supersecret'

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

# my id is 22603120

Instagram.configure do |config|
  config.client_id = "5afc81320ca54c1596940930c5e0e38b"
  config.client_secret = "6974a7b4f20d46babd1e1926fa99d031"
end

get "/" do
  '<a href="/oauth/connect">Connect with Instagram</a>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/feed"
end

get "/feed" do
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  friendsLikers = {}
  friendsPhotos = {}

  html = "<h1>#{user.username}'s Top Instragram Friends!</h1>"
  html << "<ul>"
  # pp client.user_recent_media
  client.user_recent_media.each do |item|
    # html << "<img src='#{media_item.images.thumbnail.url}'>"
    html << "<li><b>#{item.caption.text}</b> (#{item.likes['count']} likes)"
    if item.likes['count'] > 0
      html << "<ul>"
      like_info = Instagram.media_likes(item.id)
      like_info.each do |liker|
        html << "<li><img src='#{liker.profile_picture}' width='30' height='30'> #{liker.username}</li>"
        if friendsLikers.has_key?(liker.username)
          friendsLikers[liker.username] += 1
        else
          friendsLikers[liker.username] = 1
          friendsPhotos[liker.username] = liker.profile_picture
        end
      end
      html << "</ul>"
    end
    html << "</li>"

    sleep 1
  end
  html << "</ul>"
  pp friendsLikers.sort_by { |username, total| total }.reverse
  html
end
