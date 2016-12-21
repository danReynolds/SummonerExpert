ruby '2.3.0'
source 'https://rubygems.org'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
gem 'pg'
gem 'google-cloud'
gem 'puma', '~> 3.0'

group :development, :production do
  gem 'redis-rails'
end

group :development, :test do
  gem 'pry'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'byebug', platform: :mri
  gem 'rspec-rails', '~> 3.5'
end

group :test do
  gem 'fakeredis'
end

group :development do
  gem 'dotenv-rails'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
