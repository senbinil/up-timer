source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
gem "pg", "~> 1.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# HTTP client with connection pooling, retries, and SSL support [https://github.com/honeyryderchuck/httpx]
gem "httpx", "~> 1.4"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Authentication [https://github.com/janko/rodauth-rails]
gem "rodauth-rails"

# Charting [https://chartkick.com]
gem "chartkick"

# Pagination [https://github.com/ddnexus/pagy]
gem "pagy"

group :development, :test do
  # Debugging with Pry [https://github.com/pry/pry]
  gem "pry-rails"
  gem "pry-byebug"
  gem "foreman", "~> 0.90.0"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "~> 8.0.5", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec testing framework
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record"
  gem "faker"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Solid Queue web dashboard
  gem "mission_control-jobs"

  # Preview emails in browser [https://github.com/ryanb/letter_opener]
  gem "letter_opener"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
# Enables Sequel to use Active Record's database connection
gem "sequel-activerecord_connection", "~> 2.0", require: false
# Used by Rodauth for password hashing
gem "bcrypt", "~> 3.1", require: false
# Used by Rodauth for rendering built-in view and email templates
gem "tilt", "~> 2.8", require: false

# Email delivery providers [https://resend.com] [https://www.mailgun.com]
gem "resend"
gem "mailgun-ruby"

gem "net-imap", ">= 0.6.4.1"
