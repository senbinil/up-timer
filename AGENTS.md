# AGENTS.md

## Project

UpTimer — a Rails 8.1 uptime monitoring app. Ruby 4.0.5. SQLite default, PostgreSQL via adapter (`DB_PROVIDER` env var). SolidQueue for background jobs (no Redis). Hotwire (Stimulus + Turbo) frontend with Tailwind CSS v4.

## Setup

```bash
rvm use ruby-4.0.5@up-timer
bundle install
cp .env.example .env   # set ADMIN_EMAILS for admin access
bin/rails db:create db:migrate db:seed
bin/dev                 # starts Puma + Tailwind watcher + SolidQueue worker
```

## Commands

| Task | Command |
|---|---|
| Start dev server | `bin/dev` (Puma on :3000 + CSS watcher + job worker) |
| Run all tests | `bundle exec rspec` |
| Run one spec file | `bundle exec rspec spec/models/monitor_spec.rb` |
| Run one test | `bundle exec rspec spec/models/monitor_spec.rb:42` |
| Lint | `bin/rubocop -f github` |
| Security scan | `bin/brakeman --no-pager` |
| Gem audit | `bin/bundler-audit` |
| Importmap audit | `bin/importmap audit` |
| DB migrate | `bin/rails db:migrate` |
| Prepare test DB | `bin/rails db:test:prepare` |
| Installer unit tests | `bash spec/installer_test.sh` |
| Installer integration tests | `bash spec/installer_integration_test.sh` |

## CI order (what PRs must pass)

1. `bin/brakeman --no-pager` + `bin/bundler-audit` (security scan)
2. `bin/importmap audit` (JS deps)
3. `bin/rubocop -f github` (lint)
4. `bin/rails db:test:prepare && bundle exec rspec` (tests against **both** SQLite and PostgreSQL)
5. Installer shell tests

## Architecture

- **Database**: SQLite in `storage/` by default. Thread pool = `RAILS_MAX_THREADS * 2` (covers Puma + SolidQueue sharing connections).
- **Background jobs**: SolidQueue runs in-process. `MonitorSchedulerJob` every 30s enqueues `MonitorCheckJob`. `DataRetentionJob` daily at 3am.
- **Auth**: Rodauth with RBAC (viewer / collaborator / admin). Admins assigned via `ADMIN_EMAILS` env var.
- **Email**: Optional. Resend or Mailgun via `MAIL_PROVIDER`. Without it, accounts auto-verify and alert emails are skipped.
- **Design system**: `DESIGN.md` is the source of truth for colors, typography, spacing, components, and dark mode. Always reference it before any UI/CSS work. Use semantic tokens (e.g. `bg-surface-container-lowest`, `text-on-surface-variant`) instead of hardcoded Tailwind values.

## Key conventions

- Tests use RSpec + FactoryBot + Shoulda Matchers + DatabaseCleaner.
- Linter is `rubocop-rails-omakase` (Rails default style, no custom overrides).
- `db/schema.rb` is in `.agentignore` — do not edit or reference it.
- Installer tests are bash-based (`spec/installer_test.sh`, `spec/installer_integration_test.sh`), separate from RSpec.
- Feature branch naming: `feature/<short-description>`.
- Commit format: `type(scope): description` (e.g. `fix(monitor): handle timeout`).

## Workflow (STRICT MODE)

Follow this sequence exactly. No step may be skipped or reordered.

1. **Plan (read-only)** — Understand the requirement. Identify impacted files, risks, and edge cases. Propose a strategy. **No code changes, no branch changes, no commits.**
2. **Wait for user approval** — Agent MUST stop and wait. Valid responses: `approve` → proceed, `change plan` → revise and return to step 1. **No proceeding without explicit approval.**
3. **Create feature branch** (`feature/<short-description>`) — Only after approval. **Never implement before branch switch.**
4. **Implement** — Scope strictly to approved plan. **No scope creep, no unrelated refactors, no unapproved dependency or architecture changes.**
5. **Verify** — Run lint and tests. **No skipping verification.**
6. **Final approval** — Present summary, modified files, and impact description. **No commit without approval.**
7. **Commit and push** — Only after final approval; push only after commit.

## .agentignore compliance

Respect `.agentignore`. Do not read, modify, or reference ignored files unless the user explicitly requests it. If a task requires an ignored file, ask first.

## Scope boundary

All file reads and exploration MUST stay within the project root directory. Never read parent or sibling directories. Start all exploration from the current working directory.

## Override policy

Workflow rules may only be bypassed if the user explicitly writes `override workflow rule` or specifies the step to skip/modify. Otherwise, strict mode is enforced.
