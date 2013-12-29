# アプリ名の取得
@app_name = app_name

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

if yes?('Use MongoDB?')
append_file 'Gemfile', <<-CODE
gem 'mongoid'
gem 'bson'
gem 'bson_ext'
CODE

end

# bundle install
run 'bundle install'

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
#{@app_name.classify}::Application.config.secret_key_base = ENV['SECRET_KEY_BASE'] || 'sometoken'
FILE

# set Japanese locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# create git ignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore'

# Setting Rspec
run 'rails generate rspec:install'
run "echo '--color --drb -f d' > .rspec"

insert_into_file 'spec/spec_helper.rb',
%(config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end
), after: 'RSpec.configure do |config|'

# git init
git :init
git :add => '.'
git :commit => "-a -m 'first commit'"