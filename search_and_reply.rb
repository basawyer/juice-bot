#!/usr/bin/env ruby

require 'sqlite3'
require 'twitter'


POSSIBLE_FIRST_REPLIES = [
  -> (username) { "Awesome @#{username}, but what is juice?!?" },
  -> (username) { "Wait what is juice @#{username}?!?" }
]

# Open a database
db = SQLite3::Database.new 'replies.db'

# Create a table
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS replies (
    tweet_url varchar(255),
    tweet_id bigint
  );
SQL

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
end

search_options = { result_type: 'recent' }

client.search("'grape juice'", search_options).take(5).each do |tweet|
  count = db.execute("SELECT count(1) FROM replies WHERE tweet_id = ?", tweet.id).flatten.first
  if count == 0
    db.execute("INSERT INTO replies (tweet_id, tweet_url) VALUES (?, ?)", [tweet.id, tweet.url.to_s]) if count == 0
    text = POSSIBLE_FIRST_REPLIES[rand(0..POSSIBLE_FIRST_REPLIES.count-1)].call(tweet.user.screen_name)
    client.update(text, in_reply_to_status_id: tweet.id)
    sleep(60)
  end
end

