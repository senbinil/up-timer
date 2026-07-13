# Adapter Pattern in UpTimer

UpTimer uses an **adapter (strategy) pattern** for pluggable service providers. This allows switching between implementations at runtime via environment variables — no code changes needed.

Two adapters use this pattern:

- **`MailAdapter`** — Email delivery (Resend, Mailgun, or null)
- **`DbAdapter`** — Database provider (SQLite or PostgreSQL)

---

## How It Works

```
Boot → config/initializers/<adapter>.rb
         │
         ├─ Reads ENV["PROVIDER_KEY"]
         │
         └─ Calls <Module>::<Provider>.configure!
                                       │
                                       ├─ Sets up the provider
                                       └─ Logs the result
```

### Flow

1. An **initializer** in `config/initializers/` reads the provider env var
2. It `require`s the module and all provider files
3. Based on the env var value, it calls the matching provider's `configure!` class method
4. Each provider's `configure!` sets up the necessary connections/configs
5. A `configured?` method (on the module) allows runtime checks elsewhere in the app

---

## MailAdapter

Switches email delivery provider at runtime.

### Environment Variable

```
MAIL_PROVIDER=resend | mailgun | (unset)
```

### Files

| File                                  | Purpose                           |
| ------------------------------------- | --------------------------------- |
| `config/initializers/mail_adapter.rb` | Bootstrapper                      |
| `lib/mail_adapter.rb`                 | Module with `configured?` helper  |
| `lib/mail_adapter/null_adapter.rb`    | Fallback — logs + swallows emails |
| `lib/mail_adapter/resend.rb`          | Resend provider                   |
| `lib/mail_adapter/mailgun.rb`         | Mailgun provider                  |

### Adding a New Provider

1. Create `lib/mail_adapter/<provider>.rb`
2. Implement a `self.configure!` method that:
   - Validates required env vars are present
   - Configures the delivery method
   - Returns `true` on success, `false` on failure
   - Logs the result
3. Add a `when "<provider>"` case to the initializer
4. Add the provider's gem to the `Gemfile`

### Runtime Check

```ruby
MailAdapter.configured?  # => true/false
```

Used in jobs, services, and auth logic to conditionally enable email features.

---

## DbAdapter

Switches the database provider at runtime. Routes Solid Queue and Solid Cache connections to the appropriate database.

### Environment Variable

```
DB_PROVIDER=postgres | sqlite | (unset)
```

Additionally, when `DB_PROVIDER=postgres`, the app expects `DATABASE_URL` to be set (e.g. `postgres://user:pass@host:5432/dbname`).

### Files

| File                                | Purpose                                         |
| ----------------------------------- | ----------------------------------------------- |
| `config/initializers/db_adapter.rb` | Bootstrapper (production only)                  |
| `lib/db_adapter.rb`                 | Module with `configure!` dispatcher             |
| `lib/db_adapter/sqlite.rb`          | SQLite provider — no-op (default config)        |
| `lib/db_adapter/postgres.rb`        | PostgreSQL provider — routes Solid\* to primary |

### What Each Provider Does

#### SQLite (`DbAdapter::Sqlite`)

- **No-op.** The `database.yml` file already configures 4 separate SQLite databases (primary, queue, cache, cable). `production.rb` pins Solid Queue to `:queue`, `cable.yml` pins Solid Cable to `:cable`, `cache.yml` pins Solid Cache to `cache`. All defaults work as-is.

#### PostgreSQL (`DbAdapter::Postgres`)

- Runs in `Rails.application.config.after_initialize` to ensure all configs are loaded
- Overrides `config.solid_queue.connects_to` to use `:primary` (which connects via `DATABASE_URL`)
- Overrides `config.solid_cache.connects_to` to use `:primary`
- Solid Cable is left as-is (uses its own config)
- The `database.yml` production SQLite configs serve as a fallback — `DATABASE_URL` overrides the primary connection

### Adding a New Provider

1. Create `lib/db_adapter/<provider>.rb`
2. Implement a `self.configure!` method
3. Add a `when "<provider>"` case to `lib/db_adapter.rb`'s `configure!` dispatcher
4. Add the provider's adapter gem to the `Gemfile`
5. If using the installer, update `deploy/installer.sh` to prompt for and configure the new provider

### Important: Sequel/Rodauth Compatibility

The `sequel-activerecord_connection` gem bridges Sequel (used by Rodauth) to ActiveRecord. The Sequel adapter must match the ActiveRecord adapter:

```ruby
# app/misc/rodauth_main.rb
sequel_adapter = {
  "sqlite3" => "sqlite",
  "postgresql" => "postgres"
}.fetch(ActiveRecord::Base.connection_db_config.configuration_hash[:adapter])
db Sequel.send(sequel_adapter, extensions: :activerecord_connection, keep_reference: false)
```

When adding a new database provider, add its ActiveRecord adapter name → Sequel adapter name mapping here.

---

## Deploy Integration

The installer (`deploy/installer.sh`) collects provider selections from the user and generates appropriate configuration:

- **Mail provider**: Written to `deploy/.env` as `MAIL_PROVIDER`
- **Database provider**: Written to `deploy/.env` as `DB_PROVIDER` + `POSTGRES_USER`/`POSTGRES_PASSWORD`. A separate `deploy/docker-compose.pg.yml` override file is generated for PostgreSQL

### Usage

```bash
# SQLite (default)
docker compose -f docker-compose.generated.yml --env-file deploy/.env up -d

# PostgreSQL
docker compose -f docker-compose.generated.yml -f deploy/docker-compose.pg.yml --env-file deploy/.env up -d
```

---

## Summary

| Aspect           | MailAdapter                          | DbAdapter                                 |
| ---------------- | ------------------------------------ | ----------------------------------------- |
| Env var          | `MAIL_PROVIDER`                      | `DB_PROVIDER`                             |
| Providers        | `null`, `resend`, `mailgun`          | `sqlite`, `postgres`                      |
| Runtime check    | `MailAdapter.configured?`            | N/A                                       |
| Initializer runs | All environments                     | Production only                           |
| Configures       | `ActionMailer::Base.delivery_method` | `solid_queue`/`solid_cache` `connects_to` |
