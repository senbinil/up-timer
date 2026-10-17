# Troubleshooting & debugging

This guide has two parts:

- **[Users & operators](#part-1--users--operators)** — simple checks for a running instance. Start here.
- **[Developers](#part-2--developers)** — local setup, container internals, and CI.

---

## Part 1 — Users & operators

### Start with these three checks

```bash
docker ps --filter name=up-timer --format '{{.Names}} {{.Status}}'   # 1. is it running?
curl -fsS -o /dev/null -w '%{http_code}\n' http://localhost/up        # 2. is it healthy? (200)
docker logs --tail=100 <container-name>                               # 3. what does it say?
```

`Up …` means the app is running. `curl` should print `200`.

### Restart or update (simplest safe way)

If you installed with the installer, use it:

```bash
./deploy/installer.sh
# choose 1) Update
```

It pulls the current image and restarts with your existing settings. This is safer than
typing `docker compose` commands by hand.

### The app is unreachable or shows an error

- Run the three checks above.
- If the container restarts in a loop, the logs usually name the cause (database or config).
- Restart with the installer (above).

### I can't sign in

Usually the app is pointed at the wrong database.

- Restart through the installer (`Update`) rather than a hand-written `docker compose`
  command — the installer always includes the correct database settings.
- Your data is safe: restarting does not delete the database volume.

### Emails aren't arriving

- Email is optional. It works only when `MAIL_PROVIDER` is `resend` or `mailgun` in
  `deploy/.env`, with a valid API key.
- Without it, accounts auto-verify and alert emails are skipped.
- Check the spam folder, then the logs for the provider's error.

### Monitors aren't checking

- The background worker must be running. Single-container installs need
  `SOLID_QUEUE_IN_PUMA=true` (the installer sets it).
- Recent results are shown on the dashboard.

### Never do this

```bash
docker compose down -v     # deletes the database volume
```

Restarting is safe; removing volumes is not.

### Where to read more

- [deploy/README.md](../deploy/README.md) — deployment modes and settings
- [deploy/.env.example](../deploy/.env.example) — every environment variable

---

## Part 2 — Developers

### Local development

```bash
bin/dev                       # Puma :3000 + Tailwind watcher + SolidQueue (foreman)
tail -f log/development.log
bin/rails console
bin/rails runner 'puts Monitor.count'
bin/rails db:migrate
bin/rails db:prepare
bin/rails db:seed
```

Common local issues:

- `bin/dev: exec: foreman: not found` → the `foreman` gem isn't on `PATH`; `rbenv rehash`.
- Tailwind styles look stale → `app/assets/builds/*` is gitignored;
  run `bin/rails tailwindcss:build`.
- `ActiveRecord::PendingMigrationError` → `bin/rails db:migrate`
  (tests: `bin/rails db:test:prepare`).

### Tests, lint, and scans

```bash
bundle exec rspec
bundle exec rspec spec/models/monitor_spec.rb:42   # single example

bash spec/installer_test.sh
bash spec/installer_integration_test.sh
bash spec/zjit_env_test.sh

bin/rubocop -f github
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

### Container internals

The installer writes `docker-compose.generated.yml` in the project root; PostgreSQL adds
`deploy/docker-compose.pg.yml`.

> **Always include the PG override when it exists.** Without it the app loses
> `DB_PROVIDER=postgres` and `DATABASE_URL`, falls back to SQLite (empty), and logins
> fail. Volumes are untouched; re-adding it reattaches the same data.

```bash
COMPOSE="docker compose -f docker-compose.generated.yml"
[ -f deploy/docker-compose.pg.yml ] && COMPOSE="$COMPOSE -f deploy/docker-compose.pg.yml"
COMPOSE="$COMPOSE --env-file deploy/.env"

$COMPOSE ps
$COMPOSE logs -f --tail=200
$COMPOSE config
```

Container diagnostics:

```bash
$COMPOSE exec up-timer printenv RAILS_ENV DB_PROVIDER ZJIT_ENABLE
$COMPOSE exec up-timer sh -c 'tr "\0" "\n" < /proc/1/environ | sort'
$COMPOSE exec up-timer sh -c 'ls -l /rails/storage'
```

Adapter status appears in the logs:

```
DbAdapter: using SQLite          # or: using PostgreSQL
MailAdapter: MAIL_PROVIDER not set — email delivery disabled
```

### Data safety and backups

- SQLite data: named volume mounted at `/rails/storage`.
- Postgres data: named volume `up-timer-pgdata` at `/var/lib/postgresql/data`.
- `up -d` re-creates containers but keeps volumes; only `down -v` deletes them.
- Compose prefixes volume names with the project name — find them with
  `docker volume ls | grep -i up-timer`.

```bash
# Postgres
$COMPOSE exec db sh -c 'pg_dump -U "$POSTGRES_USER" "${POSTGRES_DB:-uptimer}"' > uptimer.sql

# SQLite (use the real volume name)
docker run --rm -v <project>_up-timer-storage:/data -v "$PWD":/backup alpine \
  tar czf /backup/up-timer-storage.tgz -C /data .
```

### Installer upgrade gotcha

Installer **Update** (option 1) only pulls the image and runs `up -d`; it does **not**
regenerate `docker-compose.generated.yml`. Env vars added in a release (e.g.
`ZJIT_ENABLE` in 0.5.1) won't reach an existing deployment via Update. Use
**Reconfigure**, or add the line manually and re-create:

```bash
$COMPOSE up -d
```

### JIT (ZJIT / YJIT)

Ruby runs **one JIT at a time**. Rails 8.1 enables YJIT outside dev/test;
`config/application.rb` disables it when `RUBYOPT` contains `--zjit`, so only ZJIT is
requested.

Enable ZJIT:

```bash
# deploy/.env
ZJIT_ENABLE=true

# the compose service must forward it:
#   - ZJIT_ENABLE=${ZJIT_ENABLE:-false}

$COMPOSE up -d
```

Verify — the Puma boot line is definitive (`+ZJIT` appears only when enabled):

```bash
$COMPOSE logs | grep 'Ruby version'
# * Ruby version: ruby 4.0.5 … +ZJIT +PRISM [x86_64-linux]

$COMPOSE exec up-timer sh -c 'tr "\0" "\n" < /proc/1/environ | grep RUBYOPT'
# RUBYOPT=... --zjit
```

Gotchas:

- `$COMPOSE exec up-timer ruby -e 'RubyVM::ZJIT.enabled?'` always reports `false` — it
  bypasses the entrypoint that sets `RUBYOPT`. Use the boot line or `/proc/1/environ`.
- Without ZJIT in the interpreter, boot logs
  `… has no ZJIT support; continuing without JIT` and runs normally.
- Official `ruby:4.0` images already include ZJIT; no rebuild needed.

### Email and alerts (internals)

- `AlertNotificationJob` sends only when mail is configured, the alert exists, and the
  alert has no trigger (manual alert) or its trigger has `email_notify` enabled.
- Recipients are the `active` recipients.
- Production raises delivery errors, so provider failures appear in the logs.
- Development uses `letter_opener` (opens messages in the browser).

### Background jobs

- SolidQueue runs inside Puma when `SOLID_QUEUE_IN_PUMA=true` (single container).
- `MonitorSchedulerJob` runs every 30s; `DataRetentionJob` daily at 03:00
  (see `config/recurring.yml`).

```bash
bin/rails runner 'puts SolidQueue::Job.count'
```

### CI

Every PR runs, in parallel:

```bash
bin/brakeman --no-pager && bin/bundler-audit
bin/importmap audit
bin/rubocop -f github
bin/rails db:test:prepare && bundle exec rspec      # sqlite + postgres matrix
bash spec/installer_test.sh && bash spec/installer_integration_test.sh && bash spec/zjit_env_test.sh
```

- `brakeman` exit **5** with "not the latest version" is staleness, not a vulnerability:
  `bundle update brakeman`.
- Installer and ZJIT specs are bash, not RSpec.

### Handy one-liners

```bash
$COMPOSE exec up-timer ./bin/rails console
$COMPOSE exec up-timer ./bin/rails runner 'puts Monitor.count'
$COMPOSE logs -f | grep -iE 'error|fatal|exception'
docker stats --no-stream
curl -fsS -o /dev/null -w '%{http_code}\n' http://localhost/up
```
