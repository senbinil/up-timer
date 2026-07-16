# Changelog

## [0.3.0] - 2026-07-16

### Features

- **Public Status Page**: Live updates via Turbo Streams, flash messages, improved Chartkick reinitialization after DOM updates, heat strip bars with Tippy tooltips
- **PostgreSQL Support**: DbAdapter pattern (`DB_PROVIDER=postgres`) for runtime database switching
- **UI**: Help modal on public page, remove help icon from auth pages
- **Deploy**: PostgreSQL support via compose override

### Fixes

- Fix Turbo Stream redirects on Firefox form submissions
- Fix Chartkick chart loss after Turbo Stream replacements (morph stream actions)
- Fix flash messages not appearing on public status page
- Fix logout button appearing on public status page header
- Fix redundant per-check broadcasts in MonitorCheckJob
- Fix Rodauth Sequel adapter selection for PostgreSQL compatibility
- Disable Turbo Drive on all form submissions to prevent redirect issues
- Fix chart cache and "Last 24 checks" label display

### CI & Chore

- Add PostgreSQL matrix to CI test job
- Add cancel-in-progress strategy for CI runs

### Docs

- Add adapter pattern documentation
- Add PostgreSQL deployment documentation
- Add broadcasting architecture documentation updates
- Update README with PostgreSQL config and email table header

## [0.2.18] - Earlier

- Previous stable release with core monitoring, alerting, and deploy infrastructure
