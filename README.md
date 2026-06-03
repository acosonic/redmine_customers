# redmine_customers

Customer relationship tracking for Redmine. Adds a `Customer` entity (company) that can be linked to issues, with searchable name/phone/email, custom fields, group assignment, and bulk CSV import.

Originally custom-developed in 2015-2017 by **Aleksandar Pavic** (LCP Services) for a client codenamed "customers" in Mauritius. Maintained by **Bilel Kedidi** through 2019-2020 (group filter, FR translation, filter fixes). Modernized in 2026 to run on **Rails 7.2 / Ruby 3.3 / Redmine 6.1**.

## Features

- Customers as first-class entities with name, phone, email, contact_id, group
- Link issues to a customer (`belongs_to :customer` on Issue)
- Customer custom fields (separate `CustomerCustomField` type)
- Customer-aware filters in the issue query (filter issues by customer name/phone/email/group)
- Watchers extension: group-aware watcher resolution (resolves Group members)
- CSV import with field mapping + persisted import sources
- Atom/CSV/PDF export of customer list
- Top-menu link + admin panel integration
- Search integration: customers appear in global search results
- Mailer extension: CC customer's email on issue add/edit notifications

## Requirements

- Redmine 6.0+ (tested on 6.1.2)
- Ruby 3.2+ (tested on 3.3.6)
- Rails 7.2+
- PostgreSQL 12+ or MySQL 8+

## Install

```bash
cd $REDMINE_ROOT/plugins
git clone https://github.com/acosonic/redmine_customers.git
cd ..
bundle install
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_customers
sudo systemctl restart redmine     # or your Puma/Passenger service
```

Then enable the **Customers** module per-project (Project > Settings > Modules) and grant `view_customers` / `manage_customers` permissions to relevant roles (Administration > Roles).

## Upgrade from pre-2020 versions

The 2.0 port changes how monkey-patches are applied (`Module#prepend` instead of `alias_method_chain`). No data migration is required — schema is unchanged. Just deploy and restart.

## Known issues

- `customers_reports_controller` uses MySQL-specific `TIMESTAMPDIFF()`; the SLA report endpoint fails on PostgreSQL. Affects only the `/customers_reports/generate` action; the main `/customers` UI works fine.
- Same controller uses string-interpolated SQL — has a latent SQL injection. Use only with trusted users; avoid `customers_reports` until rewritten.
- `customer_imports` table currently keeps imports forever — no cleanup task.

## License

GPL v2 (matching Redmine itself). See `copyright.txt` for full notice.

## History

| Year | Who | What |
|------|-----|------|
| 2015-2017 | Aleksandar Pavic (LCP Services) | Original development for client "customers" Mauritius |
| 2019-2020 | Bilel Kedidi | Group filter, FR translation, search/filter fixes (30+ commits) |
| 2026 | Aleksandar Pavic (Inctime) | Rails 7.2 / Redmine 6.1 modernization |
