# Changelog

## [v0.3.0] - 2026-07-16

### Features
- **Dashboard**: Live broadcasts via batched Turbo Streams with real-time pause/resume updates and dedicated broadcast jobs
- **Monitoring**: Configurable failure threshold for up/down status, pause/resume monitors with full audit trail, SSL certificate details per check
- **Database**: PostgreSQL support via DbAdapter pattern (`DB_PROVIDER=postgres`)
- **Email**: Optional email delivery with graceful degradation, Mailgun EU region support (`MAILGUN_API_HOST`), Resend/Mailgun adapter pattern
- **UI**: Dark mode with class-based toggle and CSS variable overrides, PWA support, public home page with admin-selectable services, interactive alert area charts, node tags with inline picker, clipboard copy with Stimulus controller and HTTP fallback, help modal
- **Public Status Page**: Live updates via Turbo Streams, flash messages, improved Chartkick reinitialization after DOM updates, heat strip bars with Tippy tooltips
- **Auth**: Role-based access control (RBAC), forgot password fixes, settings management for all authenticated users
- **Deploy**: Self-contained interactive deployment system (`deploy/installer.sh`), Traefik reverse proxy with wildcard Let's Encrypt SSL, Kamal Proxy mode, auto-detected `RAILS_MAX_THREADS`, auto-generated `SECRET_KEY_BASE`, inline docker-compose generation, PostgreSQL compose override, Coolify deployment guide

### Fixes
- Fix Turbo Stream redirects on Firefox form submissions
- Fix Chartkick chart loss after Turbo Stream replacements
- Fix unknown/empty status on first monitor check
- Fix Mailgun delivery method initialization
- Fix Solid Queue migration paths with `if_not_exists` guards
- Fix Rodauth forgot password form injection on login failure
- Fix thread count alignment with `RAILS_MAX_THREADS` across Puma, Queue, and DB pool
- Fix deployment installer stdin handling and set -e exits
- Fix logout button appearing on public status page
- Fix per-check redundant broadcasts in MonitorCheckJob
- Fix map disappearing after broadcast updates

### CI & Chore
- Add RSpec test suite with model, request, and auth flow specs
- Add PostgreSQL matrix to CI test job
- Add cancel-in-progress strategy for CI runs
- Update dependencies: faraday (CVE-2026-54297), nokogiri, concurrent-ruby, and others
- Docker badges and restructured README with architecture diagram

### Docs
- Add adapter pattern documentation
- Add broadcasting architecture documentation
- Add deployment system documentation (Traefik, Coolify, VPS)
- Consolidate and restructure README with deployment modes

## [v0.2.1] - Earlier

- Initial stable release with core monitoring and alerting features
