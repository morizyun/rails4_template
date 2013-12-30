# アプリ名の取得
@app_name = app_name

# clean file
run 'rm README.rdoc'

# add to Gemfile
append_file 'Gemfile', <<-CODE
ruby '2.1.0'

# Bower Manager => https://rails-assets.org/

# turbolinks support
gem 'jquery-turbolinks'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# CSS Support
gem 'less-rails'

# Use unicorn as the app server
gem 'unicorn'

# Presenter Layer
gem 'draper'

# Haml
gem 'haml-rails'

# asset取得系のログを出力しない
gem 'quiet_assets'

# Form Builders
gem 'simple_form'

# 定数管理
gem 'rails_config'

# プロセス管理
gem 'foreman'

# params 引数化
gem 'action_args'

# HTML5バリデーター
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

run 'rm -rf config/initializers/secret_token.rb'
file 'config/initializers/secret_token.rb', <<-FILE
#{@app_name.classify}::Application.config.secret_key_base = ENV['SECRET_KEY_BASE'] || '#{`rake secret`}'
FILE

# set Japanese locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# turbolink
insert_into_file 'app/assets/javascripts/application.js',%(
//= require jquery.turbolinks
), after: '//= require jquery'

# HAML 
run 'rake haml:replace_erbs'

insert_into_file 'app/views/layouts/application.html.haml',%(
%script{:src=>'//netdna.bootstrapcdn.com/bootstrap/3.0.3/js/bootstrap.min.js'}
%link{:href=>'//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome.min.css', :rel=>'stylesheet'}
%link{:href=>'//netdna.bootstrapcdn.com/bootswatch/3.0.3/simplex/bootstrap.min.css', :rel=>'stylesheet'}
), after: '= csrf_meta_tags'

# Simple Form
generate 'simple_form:install --bootstrap'

# Rails config
generate 'rails_config:install'

# Kaminari config
generate 'kaminari:config'

# Database
run 'rm -rf config/database.yml'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/postgresql/database.yml -P config/'
gsub_file 'config/database.yml', /APPNAME/, @app_name
run "createuser #{@app_name} -s"
run 'bundle exec rake RAILS_ENV=development db:create'

# Unicorn
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/unicorn.rb -P config/'
run "echo 'web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb' > Procfile"

# Rspec
# ----------------------------------------------------------------
generate 'rspec:install'
run "echo '--color --drb -f d' > .rspec"

insert_into_file 'spec/spec_helper.rb',%(
  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end
), after: 'RSpec.configure do |config|'

# Errbit
# ----------------------------------------------------------------
if yes?('Use Errbit? [yes or ENTER]')
  run 'wget https://raw.github.com/morizyun/rails4_template/master/config/initializers/errbit.rb -P config/initializers'
  run 'Register app to Errbit/Airbrake'
  key_value = ask('errbit key value?')
  gsub_file 'config/initializers/errbit.rb', /%KEY_VALUE/, key_value
  run "echo 'Please Change host name in config/initializers/errbit.rb'"
end

# MongoDB
# ----------------------------------------------------------------
if yes?('Use MongoDB? [yes or ENTER]')
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
end

# git init ##
# .gitignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore'
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''

git :init
git :add => '.'
git :commit => "-a -m 'first commit'"

# Bitbucket
# ----------------------------------------------------------------
use_bitbucket = if yes?('Push Bitbucket? [yes or ENTER]')
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
if !use_bitbucket and yes?('Push GitHub? [yes or ENTER]')
  git_uri = `git config remote.origin.url`.strip
  unless git_uri.size == 0
    say 'Repository already exists:'
    say "#{git_uri}"
  else
    username = ask 'What is your GitHub username?'
    run "curl -u #{username} -d '{\"name\":\"#{@app_name}\"}' https://api.github.com/user/repos"
    git remote: %Q{ add origin git@github.com:#{username}/#{@app_name}.git }
    git push: %Q{ origin master }
  end
end

# heroku deploy
# ----------------------------------------------------------------
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
  heroku :'addons:add', 'scheduler'
  heroku :'addons:add', 'mongolab'

  git :push => 'heroku master'
  heroku :rake, "db:migrate --app #{heroku_app_name}"
  heroku :open, "--app #{heroku_app_name}"
end
