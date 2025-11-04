# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Healthcare Provider Data Platform** - a Rails 7.2 application that imports, manages, and serves NPPES (National Plan and Provider Enumeration System) data via a GraphQL API. The platform is designed for insurance brokers to query provider information, insurance plans, networks, quality metrics, and hospital affiliations.

**Key Stats:**
- 9+ million healthcare providers from NPPES
- 330+ fields per provider in flat CSV format
- Database size: ~15GB normalized data, ~10GB staging
- Import time: 20-40 minutes for full dataset

## Technology Stack

- **Framework:** Ruby on Rails 8.0.4, Ruby 3.3.6
- **Database:** PostgreSQL 14+ with full-text search (tsvector, GIN indexes)
- **Background Jobs:** Solid Queue (database-backed queue system)
- **Job Monitoring:** Mission Control — Jobs (web dashboard)
- **Authentication:** Rails 8 built-in authentication system
- **API:** GraphQL via `graphql` gem (v2.4)
- **Frontend:** Hotwire (Turbo + Stimulus), Importmap
- **Data Source:** NPPES CSV files (6+ GB) from CMS

## Database Architecture

The schema uses a **normalized, multi-table design** to handle NPPES data efficiently:

### Core Tables (NPPES Data)
- `providers` - Individual and organizational providers (9M records)
- `addresses` - Practice locations and mailing addresses (16M records)
- `taxonomies` - Provider specialties/types (normalized lookup)
- `provider_taxonomies` - Many-to-many relationship (12M records)
- `identifiers` - Medicare/Medicaid/DEA numbers (25M records)
- `states`, `cities` - Normalized geography
- `other_names`, `endpoints`, `authorized_officials`

### Enhanced Tables (Insurance Broker Features)
- `insurance_plans`, `insurance_carriers`
- `provider_insurance_plans` - Provider-plan relationships
- `provider_networks`, `provider_network_memberships`
- `provider_quality_metrics`
- `hospital_affiliations`
- `provider_credentials`
- `provider_practice_infos`
- `provider_languages`, `provider_specializations`

### Key Design Patterns
1. **Full-text search** via generated `tsvector` column on `providers.search_vector`
2. **Partial indexes** for active providers only (`WHERE deactivation_date IS NULL`)
3. **Composite indexes** for common query patterns (state + city + purpose)
4. **Blue-green deployment** for zero-downtime imports (tables with `_new` suffix)

## NPPES Import System

The import system transforms flat CSV data into normalized tables using a **staging table strategy**:

### Import Flow
1. **Staging:** Load CSV into `staging_providers` table via PostgreSQL COPY (5-10 min)
2. **Transform:** SQL transformations create normalized tables with `_new` suffix (15-25 min)
3. **Validate:** Health checks verify data integrity (2-5 min)
4. **Swap:** Atomic table rename in transaction (<1 second downtime)

### Key Files
- `db/staging_providers.sql` - Staging table DDL (330+ columns)
- `app/services/nppes_importer.rb` - Main orchestrator (600+ lines)
- `app/services/nppes_update_worker.rb` - Incremental updates
- `app/services/nppes_health_check.rb` - 11 validation checks
- `lib/tasks/nppes.rake` - Rake tasks for all operations

### Common Commands

```bash
# Database setup
bin/rails db:create db:migrate db:seed

# Full import (20-40 minutes)
rails nppes:import[/path/to/npidata.csv]

# Incremental update (10-30 minutes)
rails nppes:update[/path/to/weekly_update.csv]

# Validate data quality
rails nppes:validate

# Rollback to previous version
rails nppes:rollback

# Extract test sample
rails nppes:extract_sample[source.csv,dest.csv,10000]

# View statistics
rails nppes:stats
```

## Development Commands

```bash
# Start development server
bin/rails server

# Run tests
bin/rails test

# Run specific test file
bin/rails test test/models/provider_test.rb

# Rails console
bin/rails console

# Database console
bin/rails dbconsole

# Lint/security checks
bin/rubocop
bin/brakeman
```

## Background Jobs with Solid Queue

This project uses **Solid Queue** for persistent background job processing (database-backed, no Redis required).

### Starting the Job Worker

```bash
# Start Solid Queue supervisor (processes jobs)
bin/jobs

# Or manually via Rails
bin/rails solid_queue:start
```

### Using Background Jobs

```ruby
# Enqueue a job
NppesUpdateJob.perform_later('/path/to/weekly_update.csv')

# Enqueue with delay
NppesUpdateJob.set(wait: 1.hour).perform_later(csv_path)

# Check job status in console
rails console
> SolidQueue::Job.where(class_name: 'NppesUpdateJob').order(created_at: :desc).first
> SolidQueue::Job.where(finished_at: nil).count  # Pending jobs
> SolidQueue::FailedExecution.last  # Check failures
```

### Configuration Files

- `config/queue.yml` - Queue and worker configuration
- `config/recurring.yml` - Recurring/scheduled jobs
- `db/queue_schema.rb` - Database schema for job tables

### Database Tables

Solid Queue uses these tables (all in same database):
- `solid_queue_jobs` - Job definitions and status
- `solid_queue_ready_executions` - Jobs ready to run
- `solid_queue_scheduled_executions` - Scheduled jobs
- `solid_queue_failed_executions` - Failed jobs with errors
- `solid_queue_recurring_tasks` - Recurring job definitions
- `solid_queue_processes` - Worker process tracking

### Key Advantages

- **No Redis dependency** - Uses PostgreSQL
- **Persistent** - Jobs survive server restarts
- **Atomic** - Uses database transactions
- **Monitorable** - Query job status via SQL/ActiveRecord
- **Reliable** - Built-in retry logic and error tracking

## Mission Control — Jobs Dashboard

Access the web dashboard for monitoring background jobs at **http://localhost:3000/jobs**

### Features

- 📊 **View all jobs** by status (pending, in progress, finished, failed)
- 🔍 **Filter** by queue name and job class
- ♻️ **Retry failed jobs** individually or in bulk
- 🗑️ **Discard jobs** that shouldn't retry
- 📝 **Inspect** job arguments, errors, and stack traces
- ⏸️ **Pause/Resume** queues
- 👷 **Monitor workers** and their current jobs
- 📈 **View statistics** and job performance

### Authentication

- **Development:** Open access (no login required)
- **Production:** Requires Rails 8 authentication (login at `/session`)

### Common Tasks

```ruby
# View failed jobs
Visit: http://localhost:3000/jobs/queues/default/jobs?status=failed

# Retry all failed jobs
Click "Retry all" button in Mission Control

# Check job details
Click on any job to see full error trace and arguments
```

## Rails 8 Authentication

This project uses the built-in Rails 8 authentication system (password-based).

### Create a User

```bash
bin/rails console
> User.create!(email_address: "admin@example.com", password: "your_secure_password", password_confirmation: "your_secure_password")
```

### Sign In

Visit http://localhost:3000/session/new or just browse to `/jobs` and you'll be redirected to sign in.

### Key Features

- **Secure password hashing** with bcrypt
- **Session management** with database-backed sessions
- **Password reset** via email (configure mailer for production)
- **Remember me** functionality
- **Current user** accessible via `Current.user` anywhere in the app

### Files

- `app/models/user.rb` - User model with `has_secure_password`
- `app/models/session.rb` - Session model for tracking logins
- `app/controllers/concerns/authentication.rb` - Authentication concern
- `app/controllers/sessions_controller.rb` - Sign in/out logic
- `app/controllers/passwords_controller.rb` - Password reset logic

## GraphQL API

**Development Interface:** http://localhost:3000/graphiql

**Production Endpoint:** POST /graphql

### Common Query Patterns

```graphql
# Search providers by name and location
query {
  providers(name: "Smith", state: "CA", activeOnly: true, limit: 20) {
    npi
    fullName
    credential
    addresses { cityName, telephone }
    taxonomies { specialization }
  }
}

# Get provider by NPI
query {
  provider(npi: "1234567890") {
    fullName
    insurancePlans { planName, carrierName }
    qualityMetrics { metricName, rating }
  }
}

# Find providers by specialty and insurance
query {
  providers(
    specialty: "Pediatrics",
    city: "Boston",
    insuranceCarrier: "Blue Cross"
  ) {
    fullName
    practiceInfo { acceptsNewPatients }
  }
}
```

### Query Arguments
- `name` - Provider name search (full-text)
- `specialty` - Filter by taxonomy/specialty
- `state`, `city` - Geographic filters
- `insuranceCarrier` - Insurance plan filter
- `activeOnly` - Exclude deactivated providers (default: true)
- `limit` - Max results (default: 50)

## Key Model Patterns

### Provider Model (`app/models/provider.rb`)

```ruby
# Scopes
Provider.active                    # Non-deactivated
Provider.search_by_name("smith")   # Full-text search
Provider.in_state("CA")            # By state
Provider.with_taxonomy("207Q00000X") # By specialty

# Instance methods
provider.full_name                 # Formatted name
provider.primary_taxonomy          # Main specialty
provider.primary_location          # Practice address
provider.active?                   # Status check
```

### Important Associations
- Provider → many addresses, taxonomies, identifiers, insurance_plans
- Provider → one authorized_official (orgs only)
- ProviderTaxonomy validates: only one primary taxonomy per provider
- Address validates: only one primary location per provider

## Testing the Import System

```bash
# Quick test with 10K records
rails nppes:extract_sample[full.csv,sample.csv,10000]
rails nppes:import[sample.csv]
rails nppes:validate

# Check results in console
rails runner "puts Provider.count"
rails runner "puts Address.count"
rails runner "NppesHealthCheck.detailed_report"
```

**Expected Results (10K sample):**
- ~10,000 providers
- ~18,500 addresses (mailing + location)
- ~12,300 taxonomies
- All health checks pass

## Architecture Notes

### Why Blue-Green Deployment?
The import creates new tables (`providers_new`, etc.) and validates them before swapping. This allows:
- Zero downtime (<1 second for atomic rename)
- Easy rollback (old tables preserved as `providers_old`)
- Validation before going live

### Why Staging Table?
PostgreSQL COPY is 10-100x faster than ActiveRecord inserts:
- Raw COPY: ~20K records/sec
- ActiveRecord: ~200-500 records/sec
- For 9M records, this saves hours

### Full-Text Search Strategy
Uses PostgreSQL's built-in tsvector instead of Elasticsearch:
- Generated column: `search_vector tsvector GENERATED ALWAYS AS (...) STORED`
- GIN index for fast lookups
- Weighted: names (A) > credentials (B)
- Query: `WHERE search_vector @@ plainto_tsquery('english', 'query')`

## Common Troubleshooting

### Import Issues
- **Out of memory:** Increase PostgreSQL `shared_buffers`, `work_mem`
- **Foreign key violations:** Ensure `rails db:seed` ran (loads states/taxonomies)
- **Slow import:** Use SSD, copy CSV to local disk (not network)
- **CSV encoding errors:** NPPES uses UTF-8 with occasional bad chars

### GraphQL Issues
- **N+1 queries:** Use eager loading in resolvers (`Provider.includes(:addresses)`)
- **Slow queries:** Check indexes with `EXPLAIN ANALYZE`
- **Timeout:** Reduce `limit`, add more filters

### Database Issues
- **Disk space:** Need 100GB+ for full dataset + staging
- **Connection pool:** Default is 5, increase for concurrent requests
- **Lock timeouts:** Table swaps use ACCESS EXCLUSIVE lock briefly

## File Organization

```
app/
├── controllers/
│   ├── graphql_controller.rb        # GraphQL endpoint
│   └── providers_controller.rb      # Web UI (basic)
├── graphql/
│   ├── doctor_management_schema.rb  # Main schema
│   ├── types/                       # GraphQL types
│   │   ├── provider_type.rb
│   │   ├── query_type.rb            # Root queries
│   │   └── ...
│   └── mutations/                   # Future: mutations
├── models/                          # ActiveRecord models
│   ├── provider.rb                  # Core model
│   ├── address.rb
│   ├── taxonomy.rb
│   └── ...
├── services/                        # Business logic
│   ├── nppes_importer.rb           # Main import orchestrator
│   ├── nppes_update_worker.rb      # Incremental updates
│   └── nppes_health_check.rb       # Validation service
└── jobs/
    └── nppes_update_job.rb         # Background job wrapper

lib/tasks/
├── nppes.rake                       # Import/update tasks
└── nppes_dynamic.rake              # Dynamic task generation

db/
├── staging_providers.sql            # Staging table DDL
├── migrate/                         # Schema migrations
└── seeds.rb                         # States/taxonomies seed data

Documentation:
├── NPPES.md                         # NPPES data source reference
├── NPPES_IMPORT_STRATEGY.md        # Technical architecture
├── NPPES_IMPORT_README.md          # User guide
├── NPPES_COMMANDS_CHEATSHEET.md    # Quick reference
├── DATABASE_SCHEMA.md              # Schema documentation
├── GRAPHQL_QUERY_EXAMPLES.md       # GraphQL examples
└── PROVIDER_DATA_PLATFORM.md       # Platform overview
```

## Performance Considerations

### Query Optimization
- Use `.includes()` for associations to avoid N+1
- Add indexes for new query patterns
- Use partial indexes for common filters
- Consider database views for complex joins

### Import Optimization
- Run imports during off-peak hours
- Monitor disk I/O and memory
- Vacuum/analyze after large imports
- Consider parallelizing transformations (future)

### API Rate Limiting
Not yet implemented, but recommended for production:
- Per-IP rate limits
- API key quotas
- Query complexity limits (GraphQL)

## SQL Injection Prevention

**IMPORTANT:** The NPPES import system uses parameterized queries to prevent SQL injection:

```ruby
# ✅ GOOD - Parameterized
ActiveRecord::Base.connection.execute(
  ActiveRecord::Base.sanitize_sql_array(["SELECT * FROM providers WHERE npi = ?", npi])
)

# ❌ BAD - String interpolation
ActiveRecord::Base.connection.execute("SELECT * FROM providers WHERE npi = '#{npi}'")
```

All SQL in `nppes_importer.rb` uses either:
1. ActiveRecord query interface (automatic escaping)
2. `sanitize_sql_array` for raw SQL
3. Heredoc with no user input

## GraphQL Schema Notes

The schema name is `DoctorManagementSchema` (historical naming) but serves all provider types:
- Individuals: Doctors, NPs, PAs, Dentists, etc.
- Organizations: Hospitals, Clinics, Pharmacies, etc.

Types follow Rails naming conventions:
- `ProviderType`, `AddressType`, `TaxonomyType`, etc.
- All types inherit from `Types::BaseObject`
- Resolvers in `app/graphql/resolvers/`

## CI/CD

GitHub Actions workflows:
- `.github/workflows/claude_code_review.yml` - Claude Code Review
- `.github/workflows/claude_pr_assistant.yml` - Claude PR Assistant

## Environment Variables

**Development:** No special config needed

**Production:**
- `PROVIDER_DIRECTORY_DATABASE_PASSWORD` - Database password
- `RAILS_MAX_THREADS` - Connection pool size (default: 5)
- `NPPES_CSV_PATH` - Path to NPPES CSV (optional)

## Data Sources & Updates

**NPPES Data:**
- Download: https://download.cms.gov/nppes/NPI_Files.html
- Full file: Monthly (~6GB ZIP)
- Incremental: Weekly (~50-200K records)
- Format: CSV with 330+ columns

**Update Strategy:**
1. **Monthly full refresh** (recommended initially)
2. **Weekly incremental + quarterly full** (production)

## Future Enhancements

See `PROVIDER_DATA_PLATFORM.md` for roadmap:
- Real-time NPPES API sync
- Additional quality metric sources (HEDIS, NCQA)
- Webhook notifications for provider changes
- Export tools for broker CRM systems
- Advanced analytics dashboards

## Additional Resources

- GraphiQL Interface: http://localhost:3000/graphiql (auto-documentation)
- NPPES Documentation: See `NPPES.md`
- Database Schema: See `DATABASE_SCHEMA.md`
- Example Queries: See `GRAPHQL_QUERY_EXAMPLES.md`
