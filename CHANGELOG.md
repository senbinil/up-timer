# Changelog

## [Unreleased]

### Security

- Upgrade Ruby to 4.0.9, which fixes four regexp (Onigmo) compiler bugs
  - CVE-2026-89078: double free when parsing a pattern fails after an alternation
  - CVE-2026-93577 / CVE-2026-97229: integer overflow in the size of a compiled pattern
  - CVE-2026-110264: overflow of internal IDs in a pattern with many repeats
  - Only reachable when an application compiles attacker-controlled regular expressions; `Regexp.timeout` does not mitigate them

## [0.5.1] - 2026-10-14

### Features

- Add opt-in ZJIT compiler support via the `ZJIT_ENABLE` environment variable
  - Set `ZJIT_ENABLE=true` (or `1`, case-insensitive) to launch app processes with Ruby's `--zjit` flag
  - Requires a Ruby built with `--enable-zjit` (the official `ruby:4.0` images qualify); other builds warn and continue without a JIT
  - While ZJIT is active, YJIT is disabled for that process — Ruby runs only one JIT at a time
- Forward `ZJIT_ENABLE` through the generated compose file and installer

### Fixes

- Honour `email_notify` for recovery mail
- Honour `MAIL_FROM` for outbound mail

### CI & Chore

- Run the ZJIT shell spec in CI

### Docs

- Document the `ZJIT_ENABLE` environment variable

## [0.5.0] - 2026-10-13

### Features

- Track outages as incidents, decoupled from alerts (#155)
- Add site settings and permissions with a registration toggle (#138)
- Add fleet status overview card to nodes index (#134, #135)

### Fixes

- Report last resolved incident, ignoring insignificant blips (#155)
- Rescue `RecordNotUnique` in admin settings update to prevent a 500
- Remove dead `SiteSetting` caching infrastructure and replace raw SVGs with Lucide
- Fix release draft tag prefix, header/body formatting, and nesting (#158, #159, #160, #161)
- Stop mail adapter specs mutating ActionMailer globals (#154)
- Clean up alert chart and add services empty state (#134, #135)

### ⚠️ Behavior Changes

- Default `down_threshold` for monitors changed from 1 to 2
- Registration now defaults to disabled (enforced via `site_settings`)
- Rename `/settings` route to `/profiles`

### CI & Chore

- Add release-drafter draft workflow (#157)
- Update `AGENTS.md` with installer shell tests
- Disable PR review workflow

### Docs

- Document registration controls and admin toggle in README (#162)
- Consolidate `agent.md` into `AGENTS.md` (#137)
- Restructure README for new users and fix outdated info (#156)

### Dependencies

- Bump rails from 8.1.3.1 to 8.1.4 (#147)
- Bump pg from 1.6.3 to 1.7.0 (#153)
- Bump solid_cable from 4.0.2 to 4.1.0 (#145)
- Bump image_processing from 2.0.3 to 2.2.0 (#130, #149)
- Bump pagy from 43.6.2 to 43.7.0 (#148)
- Bump resend from 1.13.0 to 1.17.0 (#132, #141, #144, #146)
- Bump selenium-webdriver from 4.48.0 to 4.50.0 (#140, #150)
- Bump mailgun-ruby from 1.4.4 to 1.4.5 (#152)
- Bump bootsnap from 1.25.0 to 1.26.0 (#133)
- Bump mini_magick from 5.3.3 to 5.4.0 (#131)
- Bump net-imap from 0.6.6 to 0.6.7 (#143)
- Bump mission_control-jobs from 1.2.0 to 1.3.1 (#142)
- Update brakeman to 8.1.0 and drop the version pin

## [0.4.4] - 2026-09-05

### CI & Chore

- Add up-reviewer for automated PR code reviews (#128)

### Dependencies

- Bump resend from 1.10.0 to 1.13.0 (#124)
- Bump thruster from 0.1.25 to 0.1.26 (#125)
- Bump pagy from 43.6.1 to 43.6.2 (#126)
- Bump selenium-webdriver from 4.47.0 to 4.48.0 (#127)
- Bump mission_control-jobs from 1.1.0 to 1.2.0 (#129)

## [0.4.3] - 2026-08-27

### Dependencies

- Bump bootsnap from 1.24.6 to 1.25.0 (#116)
- Bump rodauth-rails from 2.1.2 to 2.2.2 (#117)
- Bump thruster from 0.1.22 to 0.1.25 (#118)
- Bump image_processing from 2.0.2 to 2.0.3 (#119)
- Bump solid_queue from 1.4.0 to 1.7.0 (#120)
- Bump selenium-webdriver from 4.46.0 to 4.47.0 (#121)
- Bump solid_cable from 4.0.0 to 4.0.2 (#122)
- Bump resend from 1.7.0 to 1.10.0 (#123)

## [0.4.2] - 2026-08-20

### Features

- Switch Active Storage variants to ImageMagick (#115)

### Docs

- Document `/rails/db` volume shadowing fix (#114)

### Dependencies

- Bump image_processing from 1.14.0 to 2.0.2 (#3)
- Bump tailwindcss-rails from 4.4.0 to 4.6.0 (#37)
- Bump kamal from 2.11.0 to 2.12.0 (#38)
- Bump shoulda-matchers from 6.5.0 to 8.0.1 (#53)
- Bump rspec-rails from 7.1.1 to 8.0.4 (#54)
- Bump thruster from 0.1.21 to 0.1.22 (#55)
- Bump resend from 1.3.0 to 1.7.0 (#93)
- Bump selenium-webdriver from 4.44.0 to 4.46.0 (#94)
- Bump pagy from 43.5.6 to 43.6.1 (#95)
- Bump tilt from 2.7.0 to 2.8.0 (#96)

## [0.4.1] - 2026-08-04

### Fixes

- Upgrade Rails to 8.1.3.1 to patch an Active Storage CVE (#113)
- Stop shadowing the `/rails/db` volume so migrations deploy (#112)

## [0.4.0] - 2026-07-28

### Features

- Add human-friendly check interval input and display (#102)
- Replace map with geo-location details stored in JSONB (#103)

### Fixes

- Remove duplicate settings link from sidebar (#100)
- Unify shield icon (#111)

## [0.3.7] - 2026-07-19

### Fixes

- Auth form mobile padding (#99)

## [0.3.6] - 2026-07-19

### Features

- Extract FleetStatsService, switch to httpx, refactor dashboard broadcast (#97)

### Fixes

- Fix Mailgun API host not being forwarded to delivery method (#98)

_Note: tags 0.3.1–0.3.5 were released without changelog entries._

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
