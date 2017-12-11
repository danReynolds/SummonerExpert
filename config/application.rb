require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require './lib/action_router.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SummonerExpert
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.middleware.insert_after Rack::ETag, ActionRouter

    # In development autoload of paths is enabled, meaning that requires are done
    # lazily so not as to burden startup of a rails console for example. In
    # production we want to eager load additional files so that they are already
    # required which also prevents threading problems.
    if Rails.env.production?
      config.eager_load_paths += %W(#{config.root}/lib)
    else
      config.autoload_paths += %W(#{config.root}/lib)
    end

    config.api_only = true
  end
end
