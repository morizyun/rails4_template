# アプリ名の取得
@app_name = app_name

# clean file
run 'rm README.rdoc'

# .gitignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''
gsub_file '.gitignore', /^config\/secret.yml$/, ''

# add to Gemfile
append_file 'Gemfile', <<-CODE
ruby '2.1.0'

# Bower Manager => https://rails-assets.org/
source 'https://rails-assets.org'

# turbolinks support
gem 'jquery-turbolinks'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# CSS Support
gem 'less-rails'

# App Server
gem 'unicorn'

# Presenter Layer
gem 'draper'

# Haml
gem 'haml-rails'

# Assets log cleaner
gem 'quiet_assets'

# Form Builders
gem 'simple_form'

# # Process Management
gem 'foreman'

# HTML5 Validator
gem 'html5_validators'

# PG/MySQL Log Formatter
gem 'rails-flog'

# Migration Helper
gem 'migrant'

# Pagenation
gem 'kaminari'

# NewRelic
gem 'newrelic_rpm'

# Airbrake
gem 'airbrake'

# HTML Parser
gem 'nokogiri'

# App configuration
gem 'figaro'

# Hash extensions
gem 'hashie'

# Twitter Bootstrap
gem 'twitter-bootswatch-rails', '~> 3.1.1'
gem 'twitter-bootswatch-rails-helpers'

# Settings
gem 'settingslogic'

# Cron Manage
gem 'whenever', require: false

group :development do
  # Converter erb => haml
  gem 'erb2haml'
end

group :development, :test do
  # Pry & extensions
  gem 'pry-rails'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'rb-readline'

  # PryでのSQLの結果を綺麗に表示
  gem 'hirb'
  gem 'hirb-unicode'

  # pryの色付けをしてくれる
  gem 'awesome_print'

  # Rspec
  gem 'rspec-rails'

  # fixtureの代わり
  gem "factory_girl_rails"

  # テスト環境のテーブルをきれいにする
  gem 'database_rewinder'

  # Feature Test
  gem 'capybara'

  # Time Mock
  gem 'timecop'

  # Deploy
  gem 'capistrano', '~> 3.2.1'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano3-unicorn'

  # Rack Profiler
  # gem 'rack-mini-profiler'
end

group :test do
  # HTTP requests用のモックアップを作ってくれる
  gem 'webmock'
  gem 'vcr'
end

group :production, :staging do
  # ログ保存先変更、静的アセット Heroku 向けに調整
  gem 'rails_12factor'
end
CODE

# install gems
run 'bundle install'

# set config/application.rb
application  do
  %q{
    # Set timezone
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

    # 日本語化
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja

    # generatorの設定
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
      g.test_framework  :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.view_specs false
      g.controller_specs false
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end

    # libファイルの自動読み込み
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  }
end

# set Japanese locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# application.js(turbolink setting)
run 'rm -rf app/assets/javascripts/application.js'
run 'wget https://raw.github.com/morizyun/rails4_template/master/app/assets/javascripts/application.js -P app/assets/javascripts/'

# HAML
run 'rake haml:replace_erbs'

# Bootstrap/Bootswach/Font-Awaresome
insert_into_file 'app/views/layouts/application.html.haml',%(
%script{:src=>'//netdna.bootstrapcdn.com/bootstrap/3.0.3/js/bootstrap.min.js'}
%link{:href=>'//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome.min.css', :rel=>'stylesheet'}
%link{:href=>'//netdna.bootstrapcdn.com/bootswatch/3.0.3/simplex/bootstrap.min.css', :rel=>'stylesheet'}
), after: '= csrf_meta_tags'

# Simple Form
generate 'simple_form:install --bootstrap'

# Whenever
run 'wheneverize .'

# Capistrano
run 'bundle exec cap install'

# Setting Logic
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/application.yml -P config/'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/initializers/settings.rb -P config/initializers/'

# Kaminari config
generate 'kaminari:config'

# Database
run 'rm -rf config/database.yml'
if yes?('Use MySQL?([yes] else PostgreSQL)')
  run 'wget https://raw.github.com/morizyun/rails4_template/master/config/mysql/database.yml -P config/'
else
  run 'wget https://raw.github.com/morizyun/rails4_template/master/config/postgresql/database.yml -P config/'
  run "createuser #{@app_name} -s"
end

gsub_file 'config/database.yml', /APPNAME/, @app_name
run 'bundle exec rake RAILS_ENV=development db:create'

# Unicorn(App Server)
run 'mkdir config/unicorn'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn/development.rb -P config/unicorn/'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn/production.rb -P config/unicorn/'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn/staging.rb -P config/unicorn/'
run "echo 'web: bundle exec unicorn_rails -c config/unicorn/development.rb\ntest: bundle exec guard start' > Procfile"

# Rspec/Spring/Guard
# ----------------------------------------------------------------
# Rspec
generate 'rspec:install'
run "echo '--color --drb -f d' > .rspec"

insert_into_file 'spec/spec_helper.rb',%(
  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end

  config.before :all do
    FactoryGirl.reload
    FactoryGirl.factories.clear
    FactoryGirl.sequences.clear
    FactoryGirl.find_definitions
  end

  config.include FactoryGirl::Syntax::Methods
), after: 'RSpec.configure do |config|'

insert_into_file 'spec/spec_helper.rb', "\nrequire 'factory_girl_rails'", after: "require 'rspec/rails'"
gsub_file 'spec/spec_helper.rb', "require 'rspec/autorun'", ''

# Guard
run 'bundle exec guard init'
gsub_file 'Guardfile', 'guard :rspec do', "guard :rspec, cmd: 'spring rspec -f doc' do"

# Errbit
# ----------------------------------------------------------------
if yes?('Use Errbit? [yes or ELSE]')
  run 'wget https://raw.github.com/morizyun/rails4_template/master/config/initializers/errbit.rb -P config/initializers'
  run 'Register app to Errbit/Airbrake'
  key_value = ask('errbit key value?')
  gsub_file 'config/initializers/errbit.rb', /%KEY_VALUE/, key_value
  run "echo 'Please Change host name in config/initializers/errbit.rb'"
end

# MongoDB
# ----------------------------------------------------------------
use_mongodb = if yes?('Use MongoDB? [yes or ELSE]')
append_file 'Gemfile', <<-CODE
\n# Mongoid
gem 'mongoid', '4.0.0.alpha1'
gem 'bson_ext'
gem 'origin'
gem 'moped'
CODE

run 'bundle install'

generate 'mongoid:config'

append_file 'config/mongoid.yml', <<-CODE
production:
  sessions:
    default:
      uri: <%= ENV['MONGOLAB_URI'] %>
CODE

append_file 'spec/spec_helper.rb', <<-CODE
require 'rails/mongoid'
CODE

insert_into_file 'spec/spec_helper.rb',%(
  # Clean/Reset Mongoid DB prior to running each test.
  config.before(:each) do
    Mongoid::Sessions.default.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
), after: 'RSpec.configure do |config|'
end

# Eventmachine
# ----------------------------------------------------------------
use_heroku_worker = if yes?('Use eventmachine(worker process)? [yes or ELSE]')
append_file 'Gemfile', <<-CODE
\n# EventMachine/Twitter Stream API
gem 'eventmachine'
gem 'tweetstream'
CODE

run 'bundle install'

run 'mkdir lib/eventmachine'
run 'wget https://raw.github.com/morizyun/rails4_template/master/lib/eventmachine/twitter_stream.rb -P lib/eventmachine/'

append_file 'Procfile', <<-CODE
worker: bundle exec ruby lib/eventmachine/twitter_stream.rb
CODE

tw_setting = %(
  TWITTER_CONSUMER_KEY:
  TWITTER_CONSUMER_SECRET:
  TWITTER_OAUTH_TOKEN:
  TWITTER_OAUTH_TOKEN_SECRET:)
insert_into_file 'config/application.yml', tw_setting, after: 'development:'
append_file 'config/application.yml', tw_setting
end

# Redis
# ----------------------------------------------------------------
use_redis = if yes?('Use Redis? [yes or ELSE]')
append_file 'Gemfile', <<-CODE
\n# Redis
gem 'redis-objects'
gem 'redis-namespace'
CODE

run 'bundle install'

run 'wget https://raw.github.com/morizyun/rails4_template/master/config/initializers/redis.rb -P config/initializers/'
end

# git init
# ----------------------------------------------------------------
git :init
git :add => '.'
git :commit => "-a -m 'first commit'"

# heroku deploy
# ----------------------------------------------------------------
if yes?('Use Heroku? [yes or ELSE]')
  def heroku(cmd, arguments="")
    run "heroku #{cmd} #{arguments}"
  end

  # herokuに不要なファイルを設定
  file '.slugignore', <<-EOS.gsub(/^  /, '')
  *.psd
  *.pdf
  test
  spec
  features
  doc
  docs
  EOS

  git :add => '.'
  git :commit => "-a -m 'Configuration for heroku'"

  heroku_app_name = @app_name.gsub('_', '-')
  heroku :create, "#{heroku_app_name}"

  # config
  run 'heroku config:set SECRET_KEY_BASE=`rake secret`'
  run 'heroku config:add TZ=Asia/Tokyo'

  # addons
  heroku :'addons:add', 'logentries'
  heroku :'addons:add', 'scheduler'
  heroku :'addons:add', 'mongolab' if use_mongodb
  heroku :'addons:add', 'rediscloud' if use_redis

  git :push => 'heroku master'
  heroku :run, "rake db:migrate --app #{heroku_app_name}"

  # scale worker
  if use_heroku_worker
    heroku 'scale web=0'
    heroku 'scale worker=1'
  end

  # newrelic
  if yes?('Use newrelic?[yes or ELSE]')
    heroku :'addons:add', 'newrelic'
    heroku :'addons:open', 'newrelic'
    run 'wget https://raw.github.com/morizyun/rails4_template/master/config/newrelic.yml -P config/'
    gsub_file 'config/newrelic.yml', /%APP_NAME/, @app_name
    key_value = ask('Newrelic licence key value?')
    gsub_file 'config/newrelic.yml', /%KEY_VALUE/, key_value
  end
end

# Bitbucket
# ----------------------------------------------------------------
use_bitbucket = if yes?('Push Bitbucket? [yes or ELSE]')
  git_uri = `git config remote.origin.url`.strip
  if git_uri.size == 0
    username = ask 'What is your Bitbucket username?'
    password = ask 'What is your Bitbucket password?'
    run "curl -k -X POST --user #{username}:#{password} 'https://api.bitbucket.org/1.0/repositories' -d 'name=#{@app_name}&is_private=true'"
    git remote: "add origin git@bitbucket.org:#{username}/#{@app_name}.git"
    git push: 'origin master'
  else
    say 'Repository already exists:'
    say "#{git_uri}"
  end
  true
else
  false
end

# GitHub
# ----------------------------------------------------------------
if !use_bitbucket and yes?('Push GitHub? [yes or ELSE]')
  git_uri = `git config remote.origin.url`.strip
  unless git_uri.size == 0
    say 'Repository already exists:'
    say "#{git_uri}"
  else
    email = ask 'What is your GitHub login E-Mail address?'
    run "curl -u #{email} -d '{\"name\":\"#{@app_name}\"}' https://api.github.com/user/repos"
    username = ask 'What is your GitHub username?'
    git remote: %Q{ add origin git@github.com:#{username}/#{@app_name}.git }
    git push: %Q{ origin master }
  end
end
