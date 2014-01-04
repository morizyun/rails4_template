namespace = [Rails.application.class.parent_name, Rails.env].join ':'
if Rails.env.production?
  # herokuの初期 asset compileでENVがうまく読み込まれていないっぽいので対策
  if ENV['REDISCLOUD_URL']
    redis_uri = URI(ENV['REDISCLOUD_URL'])
    Redis.current = Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password)
    Redis.current = Redis::Namespace.new(namespace, Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password))
  end
else
  Redis.current = Redis::Namespace.new(namespace, Redis.new(host: '127.0.0.1', port: 6379))
end