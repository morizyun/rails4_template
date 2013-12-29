# clean file
run 'rm README.rdoc'

# add to Gemfile
append_file 'Gemfile', <<-CODE
ruby '2.1.0'
gem 'rspec-rails', group: 'test'
gem 'pg'
CODE

if yes?('Use MongoDB?')
  gem 'mongoid'
end

# bundle install
run 'bundle install'

# git init
git :init
git :add => '.'
git :commit => "-a -m 'first commit'"