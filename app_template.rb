# アプリ名の取得
@app_name = app_name.gsub('-', '_')

# clean file
run 'rm README.rdoc'

# add to Gemfile
append_file 'Gemfile', <<-CODE
ruby '2.1.0'

# 定数管理
gem 'rails_config'

# プロセス管理
gem 'foreman'

# NewRelic
gem 'newrelic_rpm'

group :development do
  # erbからhamlに変換
  gem 'erb2haml'
end

group :development, :test do
  # Rails application preloader
  gem 'spring'

  # Railsコンソールの多機能版
  gem 'pry-rails'

  # pryの入力に色付け
  gem 'pry-coolline'

  # デバッカー
  gem 'pry-byebug'

  # Pryでの便利コマンド
  gem 'pry-doc'

  # PryでのSQLの結果を綺麗に表示
  gem 'hirb'
  gem 'hirb-unicode'

  # pryの色付けをしてくれる
  gem 'awesome_print'
end

group :test do
  # Rspec
  gem 'rspec-rails'

  # fixtureの代わり
  gem "factory_girl_rails"

  # テスト環境のテーブルをきれいにする
  gem 'database_rewinder'
end

group :production, :staging do
  # ログ保存先変更、静的アセット Heroku 向けに調整
  gem 'rails_12factor'
end
CODE

# bundle install
# TODO REMOVE AFTER TEST
#run 'bundle install'

# set config/application.rb
application  <<-GENERATORS
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
    g.helper_specs false
  end
GENERATORS

run 'rm -rf config/initializers/secret_token.rb'
file 'config/initializers/secret_token.rb', <<-FILE
#{@app_name.classify}::Application.config.secret_key_base = ENV['SECRET_KEY_BASE'] || '#{`rake secret`}'
FILE

# set Japanese locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# create git ignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore'
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''

# Setting Rspec
run 'rails generate rspec:install'
run "echo '--color --drb -f d' > .rspec"

insert_into_file 'spec/spec_helper.rb',
%(
  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end
), after: 'RSpec.configure do |config|'

# Database
run 'rm -rf config/database.yml'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/postgresql/database.yml -P config/'
gsub_file 'config/database.yml', /APPNAME/, @app_name
run "createuser #{@app_name} -s"
run 'bundle exec rake RAILS_ENV=development db:create'

# Unicorn
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn.rb -P config/'
run "echo 'web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb' > Procfile"

## MongoDB ###################################################
if yes?('Use MongoDB? [yes or ENTER]')
append_file 'Gemfile', <<-CODE
  # Mongoid
  gem 'mongoid', '4.0.0.alpha1'
  gem 'bson_ext'
  gem 'origin'
  gem 'moped'
CODE

  run 'bundle install'

  run 'rails generate mongoid:config'

  append_file 'config/mongoid.yml', <<-CODE
    production:
      sessions:
        default:
          uri: <%= ENV['MONGOLAB_URI'] %>
  CODE
end

# git init
git :init
git :add => '.'
git :commit => "-a -m 'first commit'"

## heroku deploy #############################################
if yes?('Use Heroku? [yes or ENTER]')
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

  heroku_app_name = "#{@app_name}#{rand(100)}".gsub('_', '-')
  heroku :create, "#{heroku_app_name}"

# config
  run 'heroku config:set SECRET_KEY_BASE=`rake secret`'
  run 'heroku config:add TZ=Asia/Tokyo'

# addons
  heroku :'addons:add', 'newrelic'
  heroku :'addons:add', 'logentries'
  heroku :'addons:add', 'mongolab'

  git :push => 'heroku master'
  heroku :rake, "db:migrate --app #{heroku_app_name}"
  heroku :open, "--app #{heroku_app_name}"
end

