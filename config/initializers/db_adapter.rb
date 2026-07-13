require "db_adapter"
require "db_adapter/sqlite"
require "db_adapter/postgres"

if Rails.env.production?
  DbAdapter.configure!
end
