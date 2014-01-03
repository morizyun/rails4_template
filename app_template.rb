# アプリ名の取得
@app_name = app_name

# clean file
run 'rm README.rdoc'

# .gitignore
run 'brew install gibo'
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore'
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''

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
gem 'puma'

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

group :development do
  # Converter erb => haml
  gem 'erb2haml'
end

group :development, :test do
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

  # Rspec
  gem 'rspec-rails'
  gem 'rake_shared_context'

  # fixtureの代わり
  gem "factory_girl_rails"

  # テスト環境のテーブルをきれいにする
  gem 'database_rewinder'

  # Guard
  gem 'guard-rspec'
  gem 'guard-spring'

  # Rails/Rack Profiler
  gem 'speed_gun'
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

run 'rm -rf config/initializers/secret_token.rb'
file 'config/initializers/secret_token.rb', <<-FILE
#{@app_name.classify}::Application.config.secret_key_base = ENV['SECRET_KEY_BASE'] || '#{`rake secret`}'
FILE

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

# Figaro
append_file '.gitignore', <<-FILE
  config/application.yml
FILE

run 'wget https://raw.github.com/morizyun/rails4_template/master/config/application.yml -P config/'

# Kaminari config
generate 'kaminari:config'
generate 'kaminari:views  bootstrap'

run 'rm -rf app/view/kaminari/_paginator.html.haml'
file 'app/view/kaminari/_paginator.html.haml', <<-FILE
= paginator.render do
  .pagination{style: 'text-align: center; display: block;'}
    %ul.pagination
      = first_page_tag unless current_page.first?
      = prev_page_tag unless current_page.first?
      - each_page do |page|
        - if page.left_outer? || page.right_outer? || page.inside_window?
          = page_tag page
        - elsif !page.was_truncated?
          = gap_tag
      = next_page_tag unless current_page.last?
      = last_page_tag unless current_page.last?
FILE

# Database
run 'rm -rf config/database.yml'
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/postgresql/database.yml -P config/'
gsub_file 'config/database.yml', /APPNAME/, @app_name
run "createuser #{@app_name} -s"
run 'bundle exec rake RAILS_ENV=development db:create'

# Puma(App Server)
run 'wget https://raw.github.com/morizyun/rails4_template/master/config/initializers/after_initialize.rb -P config/initializers/'
run "echo 'web: bundle exec puma -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2} -p $PORT -e ${RACK_ENV:-development}' > Procfile"

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
  end

  config.include FactoryGirl::Syntax::Methods
), after: 'RSpec.configure do |config|'

insert_into_file 'spec/spec_helper.rb', "\nrequire 'factory_girl_rails'", after: "require 'rspec/rails'"
gsub_file 'spec/spec_helper.rb', "require 'rspec/autorun'", ''

# Spring
run 'wget https://raw.github.com/jonleighton/spring/master/bin/spring -P bin/'
run 'sudo chmod a+x bin/spring'

# Guard
run 'guard init'
gsub_file 'Guardfile', 'guard :rspec do', "guard :rspec, cmd: 'spring rspec -f doc' do"

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

run 'wget -N https://raw.github.com/morizyun/rails4_template/master/config/mongoid.yml -P config/'

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
use_heroku_worker = if yes?('Use eventmachine? [yes or ELSE]')
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
  TWITTER_OAUTH_TOKEN_SECRET:
)
insert_into_file 'confg/application.yml', tw_setting, after: 'development:'
insert_into_file 'confg/application.yml', tw_setting, after: 'production:'
end

# git init ##
# ----------------------------------------------------------------
git :init
git :add => '.'
git :commit => "-a -m 'first commit'"

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

  heroku_app_name = @app_name.gsub('_', '-')
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

  # scale worker
  if use_heroku_worker
    heroku 'scale web=0'
    heroku 'scale worker=1'
  end

  # set newrelic key
  heroku :'addons:open', 'newrelic'
  run 'wget https://raw.github.com/morizyun/rails4_template/master/config/newrelic.yml -P config/'
  gsub_file 'config/newrelic.yml', /%APP_NAME/, @app_name
  key_value = ask('Newrelic licence key value?')
  gsub_file 'config/newrelic.yml', /%KEY_VALUE/, key_value
end

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
