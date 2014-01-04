namespace = [Rails.application.class.parent_name, Rails.env].join ':'
if Rails.env.production?
  redis_uri = URI(ENV['REDISCLOUD_URL'])
  Redis.current = Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password)
  Redis.current = Redis::Namespace.new(namespace, Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password))
else
  Redis.current = Redis::Namespace.new(namespace, Redis.new(host: '127.0.0.1', port: 6379))
end