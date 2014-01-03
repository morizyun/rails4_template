require_relative '../../config/environment'

# Twitter username => id変換: http://tweeterid.com/
@follower_id_list = ['xxxx']
@track_words = ['xxxx']

TweetStream.configure do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
  config.auth_method = :oauth
end

EM.run do
  def write_to_mongodb(status)
    EM.defer do
      $stdout.print "status: #{status}\n"
      $stdout.flush

      # statusの処理
      ## ゴニョゴニョ
    end
  end

  # Twitterのuser idをStream APIで常時チェック
  TweetStream::Client.new.on_error do |message|
    $stdout.print "message: #{message}\n"
    $stdout.flush
    Airbrake.notify(e, parameters: {message: message})
  end.follow(@follower_id_list) do |status|
    write_to_mongodb(status)
  end

  # Twitterでkeywordが出るのをStream APIで常時チェック
  TweetStream::Client.new.on_error do |message|
    $stdout.print "message: #{message}\n"
    $stdout.flush
    Airbrake.notify(e, parameters: {message: message})
  end.track(@track_words) do |status|
    write_to_mongodb(status)
  end
end