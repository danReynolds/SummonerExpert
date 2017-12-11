require "sidekiq/throttled"
Sidekiq::Throttled.setup!

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://redis:6379/0', password: ENV['REDIS_PASSWORD'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://redis:6379/0', password: ENV['REDIS_PASSWORD'] }
end
