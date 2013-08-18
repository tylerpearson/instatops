require "sinatra"
require "instagram"
require "pp"

set :session_secret, ENV["SESSION_KEY"] || 'supersecret'

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

# my id (@typearson) is 22603120

Instagram.configure do |config|
  config.client_id = "5afc81320ca54c1596940930c5e0e38b"
  config.client_secret = "6974a7b4f20d46babd1e1926fa99d031"
end

get "/" do
  erb :home
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/fans"
end

get "/fans" do
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  friendsLikers = {}

  # store friends' profile photos separately
  friendsPhotos = {}

  # go back 60
  page_1 = client.user_recent_media
  page_2_max_id = page_1.pagination.next_max_id
  page_2 = client.user_recent_media(:max_id => page_2_max_id) unless page_2_max_id.nil?
  page_3_max_id = page_2.pagination.next_max_id
  page_3 = client.user_recent_media(:max_id => page_3_max_id) unless page_3_max_id.nil?

  recent_media = page_1 + page_2 + page_3

  recent_media.each do |item|
    if item.likes['count'] > 0
      like_info = Instagram.media_likes(item.id)
      like_info.each do |liker|
        if friendsLikers.has_key?(liker.username)
          friendsLikers[liker.username] += 1
        else
          friendsLikers[liker.username] = 1
          friendsPhotos[liker.username] = liker.profile_picture
        end
      end
    end
    sleep 1
  end

  @user = user
  @likers = friendsLikers.sort_by { |username, total| total }.reverse
  @photos = friendsPhotos
  @count = recent_media.length

  erb :friends
end

get '/*' do
  erb :not_found
end
