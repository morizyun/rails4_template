# Please fix following settings
Airbrake.configure do |config|
  config.api_key = '%KEY_VALUE'
  config.host    = 'xxx.herokuapp.com'
  config.port    = 443
  config.secure  = config.port == 443
  config.development_environments = %w(development test)
end