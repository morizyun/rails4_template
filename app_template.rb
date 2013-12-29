gem 'rspec-rails', group: 'test'
gem 'pg'

if yes?('Use MongoDB?')
  gem 'mongoid'
end

