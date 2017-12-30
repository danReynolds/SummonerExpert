require 'raven'

Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN_KEY']
  config.environments = ['production']
end
