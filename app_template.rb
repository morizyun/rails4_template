require 'bundler'

# アプリ名の取得
@app_name = app_name

# メールアドレスの取得
mail_address = ask("What's your current email address?")

# clean file
run 'rm README.rdoc'

# .gitignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''
gsub_file '.gitignore', /config\/secret.yml/, ''

# add to Gemfile
append_file 'Gemfile', <<-CODE

# Bootstrap & Bootswatch & font-awesome
gem 'bootstrap-sass'
gem 'bootswatch-rails'
gem 'font-awesome-rails'

# turbolinks support
gem 'jquery-turbolinks'

# sprocket-rails (3.0.0 is not good...)
gem 'sprockets-rails', '2.3.3'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# CSS Support
gem 'less-rails'

# App Server
gem 'unicorn'

# Slim
gem 'slim-rails'

# Assets log cleaner
gem 'quiet_assets'

# Form Builders
gem 'simple_form'

# # Process Management
gem 'foreman'

# PG/MySQL Log Formatter
gem 'rails-flog'

# Pagenation
gem 'kaminari'

# NewRelic
gem 'newrelic_rpm'

# Hash extensions
gem 'hashie'

# Settings
gem 'settingslogic'

# Cron Manage
gem 'whenever', require: false

# Presenter Layer Helper
gem 'active_decorator'

# Table(Migration) Comment
gem 'migration_comments'

# Exception Notifier
gem 'exception_notification'

group :development do
  gem 'html2slim'

  # N+1問題の検出
  gem 'bullet'

  # Rack Profiler
  # gem 'rack-mini-profiler'
end

group :development, :test do
  # Pry & extensions
  gem 'pry-rails'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'rb-readline'

  # PryでのSQLの結果を綺麗に表示
  gem 'hirb'
  gem 'hirb-unicode'

  # pryの色付けをしてくれる
  gem 'awesome_print'

  # Rspec
  gem 'rspec-rails'
  gem 'spring-commands-rspec'

  # test fixture
  gem 'factory_girl_rails'

  # Deploy
  gem 'capistrano', '~> 3.2.1'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano3-unicorn'
end

group :test do
  # HTTP requests用のモックアップを作ってくれる
  gem 'webmock'
  gem 'vcr'

  # Time Mock
  gem 'timecop'

  # テスト用データを生成
  gem 'faker'

  # テスト環境のテーブルをきれいにする
  gem 'database_rewinder'
end

group :production, :staging do
  # ログ保存先変更、静的アセット Heroku 向けに調整
  gem 'rails_12factor'
end
CODE

Bundler.with_clean_env do
  run 'bundle install --path vendor/bundle --jobs=4'
end

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
      g.template_engine :slim
      g.test_framework  :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.view_specs false
      g.controller_specs true
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

# For Bullet (N+1 Problem)
insert_into_file 'config/environments/development.rb',%(
  # Bulletの設定
  config.after_initialize do
    Bullet.enable = true # Bulletプラグインを有効
    Bullet.alert = true # JavaScriptでの通知
    Bullet.bullet_logger = true # log/bullet.logへの出力
    Bullet.console = true # ブラウザのコンソールログに記録
    Bullet.rails_logger = true # Railsログに出力
  end
), after: 'config.assets.debug = true'

# Exception Notifier
insert_into_file 'config/environments/production.rb',%(
  # Exception Notifier
  Rails.application.config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[#{@app_name}] ",
      :sender_address => %{"notifier" <#{mail_address}>},
      :exception_recipients => %w{#{mail_address}}
    }
), after: 'config.active_record.dump_schema_after_migration = false'

# set Japanese locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# application.js(turbolink setting)
run 'rm -rf app/assets/javascripts/application.js'
run 'wget https://raw.github.com/morizyun/rails4_template/master/app/assets/javascripts/application.js -P app/assets/javascripts/'

# erb => slim
Bundler.with_clean_env do
  run 'bundle exec erb2slim -d app/views'
end

# Bootstrap/Bootswach/Font-Awesome
run 'rm -rf app/assets/stylesheets/application.css'
run 'wget https://raw.github.com/morizyun/rails4_template/master/app/assets/stylesheets/application.css.scss -P app/assets/stylesheets/'

# Simple Form
generate 'simple_form:install --bootstrap'

# Whenever
run 'wheneverize .'

# Capistrano
Bundler.with_clean_env do
  run 'bundle exec cap install'
end

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
Bundler.with_clean_env do
  run 'bundle exec rake RAILS_ENV=development db:create'
end

# Unicorn(App Server)
run 'mkdir config/unicorn'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn/development.rb -P config/unicorn/'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn/heroku.rb -P config/unicorn/'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn/production.rb -P config/unicorn/'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn/staging.rb -P config/unicorn/'
run "echo 'web: bundle exec unicorn -p $PORT -c ./config/unicorn/heroku.rb' > Procfile"

# Rspec/Spring/Guard
# ----------------------------------------------------------------
# Rspec
generate 'rspec:install'

run 'bundle exec spring binstub --all'

run "echo '--color -f d' > .rspec"

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

  VCR.configure do |c|
      c.cassette_library_dir = 'spec/vcr'
      c.hook_into :webmock
      c.allow_http_connections_when_no_cassette = true
  end
), after: 'RSpec.configure do |config|'

insert_into_file 'spec/spec_helper.rb', "\nrequire 'factory_girl_rails'", after: "require 'rspec/rails'"
gsub_file 'spec/spec_helper.rb', "require 'rspec/autorun'", ''

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

Bundler.with_clean_env do
  run 'bundle install'
end

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

# Redis
# ----------------------------------------------------------------
use_redis = if yes?('Use Redis? [yes or ELSE]')
append_file 'Gemfile', <<-CODE
\n# Redis
gem 'redis-objects'
gem 'redis-namespace'
CODE

Bundler.with_clean_env do
  run 'bundle install'
end

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
  run 'heroku config:add SECRET_KEY_BASE=`rake secret`'
  run 'heroku config:add TZ=Asia/Tokyo'

  # addons
  heroku :'addons:create', 'logentries'
  heroku :'addons:create', 'scheduler'
  heroku :'addons:create', 'mongolab' if use_mongodb
  heroku :'addons:create', 'rediscloud' if use_redis

  git :push => 'heroku master'
  heroku :run, "rake db:migrate --app #{heroku_app_name}"

  # newrelic
  if yes?('Use newrelic?[yes or ELSE]')
    heroku :'addons:create', 'newrelic'
    heroku :'addons:open', 'newrelic'
    run 'wget https://raw.github.com/morizyun/rails4_template/master/config/newrelic.yml -P config/'
    gsub_file 'config/newrelic.yml', /%APP_NAME/, @app_name
    key_value = ask('Newrelic licence key value?')
    gsub_file 'config/newrelic.yml', /%KEY_VALUE/, key_value
  end
end
