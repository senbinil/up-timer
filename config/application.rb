require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module UpTimer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # YJIT and ZJIT are mutually exclusive; when bin/zjit-env.sh has enabled ZJIT
    # (RUBYOPT contains --zjit), don't let Rails also turn on YJIT.
    config.yjit = false if ENV["RUBYOPT"].to_s.match?(/(?:\A|\s)--zjit(?:\s|\z)/)

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.time_zone = "Asia/Kolkata"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
