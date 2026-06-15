# Changelog

## [0.2.0] - 2026-06-15

### Added

- Email delivery via **Resend** and **Mailgun** using an adapter pattern.
- Graceful fallback to silent no-op when no provider is configured.
- Environment variables: `MAIL_PROVIDER`, `MAIL_FROM`, `RESEND_API_KEY`, `MAILGUN_API_KEY`, `MAILGUN_DOMAIN`, `APP_HOST`.

### Security

- Patched `net-imap` CVE-2026-47240, CVE-2026-47241, CVE-2026-47242 (upgraded to 0.6.4.1).

## [0.1.0] - 2026-05-28

- Initial release.
