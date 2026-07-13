module DbAdapter
  def self.configure!
    provider = ENV["DB_PROVIDER"]&.downcase

    case provider
    when "postgres" then DbAdapter::Postgres.configure!
    else
      DbAdapter::Sqlite.configure!
    end
  end
end
