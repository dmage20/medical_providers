# NPPES Import Commands - Quick Reference

## Essential Commands

### Testing (Start Here!)

```bash
# Extract 10K sample records for testing
rails nppes:extract_sample[/path/to/full_nppes.csv,/tmp/sample.csv,10000]

# Import sample data
rails nppes:import[/tmp/sample.csv]

# Validate import
rails nppes:validate

# View statistics
rails nppes:stats
```

### Full Production Import

```bash
# 1. Download NPPES file (opens browser to CMS download page)
rails nppes:download

# 2. Extract ZIP file
rails nppes:extract[/path/to/nppes_download.zip]

# 3. Run full import (20-40 minutes for 9M records)
rails nppes:import[/path/to/extracted/npidata.csv]

# 4. Validate
rails nppes:validate
rails nppes:stats
```

### Weekly Updates

```bash
# Apply weekly incremental update (background job)
rails nppes:update[/path/to/weekly_update.csv]

# Or use environment variable
NPPES_UPDATE_CSV_PATH=/path/to/weekly_update.csv rails nppes:update
```

### Maintenance

```bash
# Rollback failed import (restores previous data)
rails nppes:rollback

# View detailed health report
rails runner "NppesHealthCheck.detailed_report"

# Find data quality issues
rails runner "puts NppesHealthCheck.find_data_quality_issues"
```

---

## All Available Commands

| Command | Description | Duration |
|---------|-------------|----------|
| `rails nppes:extract_sample[src,dest,count]` | Extract sample from full file | 1-5 min |
| `rails nppes:import[csv_path]` | Full import with blue-green swap | 20-40 min |
| `rails nppes:update[csv_path]` | Apply incremental update | 10-30 min |
| `rails nppes:validate` | Quick health check | <1 min |
| `rails nppes:stats` | View import statistics | <1 min |
| `rails nppes:rollback` | Restore previous dataset | <1 min |
| `rails nppes:download` | Open CMS download page | instant |
| `rails nppes:extract[zip,dest]` | Extract NPPES ZIP file | 2-5 min |

---

## Ruby Scripts

### Extract Sample Data

```bash
ruby lib/scripts/extract_sample_nppes.rb \
  /path/to/full_nppes.csv \
  /tmp/sample_10k.csv \
  10000
```

---

## Rails Console Commands

### Validation

```ruby
# Quick health check
result = NppesHealthCheck.verify_import_health
puts result[:status]  # => 'healthy' or 'unhealthy'

# Detailed report
NppesHealthCheck.detailed_report

# Find issues
issues = NppesHealthCheck.find_data_quality_issues
issues.each { |issue| puts "⚠ #{issue}" }
```

### Statistics

```ruby
# Providers by state
NppesHealthCheck.count_providers_by_state.each_row do |row|
  puts "#{row['code']}: #{row['provider_count']}"
end

# Providers by taxonomy
NppesHealthCheck.count_providers_by_taxonomy.each_row do |row|
  puts "#{row['code']} - #{row['specialization']}: #{row['provider_count']}"
end
```

### Data Queries

```ruby
# Total counts
puts "Providers: #{Provider.count}"
puts "Individuals: #{Provider.entity_individual.count}"
puts "Organizations: #{Provider.entity_organization.count}"
puts "Active: #{Provider.where(deactivation_date: nil).count}"

# Addresses
puts "Addresses: #{Address.count}"
puts "Locations: #{Address.where(address_purpose: 'LOCATION').count}"
puts "Mailing: #{Address.where(address_purpose: 'MAILING').count}"

# Search
Provider.search_by_name('Johnson').limit(10).each do |p|
  puts p.full_name
end
```

---

## PostgreSQL Direct Queries

### Check Import Progress (during import)

```sql
-- Count staging records
SELECT COUNT(*) FROM staging_providers;

-- Count new table records (during import)
SELECT COUNT(*) FROM providers_new;
SELECT COUNT(*) FROM addresses_new;
```

### Verify Indexes

```sql
-- List all indexes on providers table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'providers';

-- Check search index exists
SELECT indexname
FROM pg_indexes
WHERE indexname = 'index_providers_on_search_vector';
```

### Data Quality Checks

```sql
-- Providers without addresses
SELECT COUNT(*) FROM providers p
LEFT JOIN addresses a ON a.provider_id = p.id
WHERE a.id IS NULL;

-- Providers without taxonomies
SELECT COUNT(*) FROM providers p
LEFT JOIN provider_taxonomies pt ON pt.provider_id = p.id
WHERE pt.id IS NULL;

-- Duplicate NPIs
SELECT npi, COUNT(*)
FROM providers
GROUP BY npi
HAVING COUNT(*) > 1;
```

---

## Environment Variables

```bash
# Import
export NPPES_CSV_PATH=/path/to/npidata.csv
rails nppes:import

# Update
export NPPES_UPDATE_CSV_PATH=/path/to/weekly_update.csv
rails nppes:update

# Extract sample
export NPPES_SOURCE_CSV=/path/to/full_nppes.csv
export SAMPLE_COUNT=50000
rails nppes:extract_sample
```

---

## Typical Workflow

### Initial Setup (First Time)

```bash
# 1. Test with sample data
rails nppes:extract_sample[/path/to/full.csv,/tmp/sample.csv,10000]
rails nppes:import[/tmp/sample.csv]
rails nppes:validate

# 2. If successful, try larger sample
rails nppes:extract_sample[/path/to/full.csv,/tmp/sample_100k.csv,100000]
rails nppes:import[/tmp/sample_100k.csv]

# 3. Full import (off-peak hours)
rails nppes:import[/path/to/full_nppes.csv]
rails nppes:validate
rails nppes:stats
```

### Monthly Maintenance

```bash
# Download latest full file
rails nppes:download
# (manually download from CMS)

# Extract
rails nppes:extract[/path/to/downloaded.zip]

# Import during low-traffic window
rails nppes:import[/path/to/extracted/npidata.csv]

# Validate
rails nppes:validate
rails nppes:stats
```

### Weekly Updates

```bash
# Download weekly incremental file from CMS
# Then apply update (runs in background)
rails nppes:update[/path/to/weekly_update.csv]

# Check logs
tail -f log/production.log
```

---

## Troubleshooting Quick Fixes

### Import Failed

```bash
# Rollback to previous data
rails nppes:rollback

# Check logs
tail -100 log/production.log

# Validate current data
rails nppes:validate
```

### Disk Full

```bash
# Drop staging table manually
rails runner "ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS staging_providers')"

# Drop old tables
rails runner "
  %w[providers addresses provider_taxonomies identifiers authorized_officials].each do |t|
    ActiveRecord::Base.connection.execute(\"DROP TABLE IF EXISTS #{t}_old CASCADE\")
  end
"
```

### Search Not Working

```sql
-- Rebuild search index
REINDEX INDEX index_providers_on_search_vector;
ANALYZE providers;
```

### Foreign Key Errors

```bash
# Re-seed states and taxonomies
rails db:seed
```

---

## Performance Tips

### PostgreSQL Configuration

```bash
# Edit postgresql.conf
shared_buffers = 2GB
work_mem = 256MB
maintenance_work_mem = 1GB
effective_cache_size = 8GB
```

### Import Optimization

```bash
# Use local file (not NFS)
# Use SSD for better I/O
# Run during off-peak hours
# Ensure sufficient RAM (16GB+ recommended)
```

---

## File Locations

```
app/services/
  ├── nppes_importer.rb          # Main import logic
  ├── nppes_update_worker.rb     # Update processing
  └── nppes_health_check.rb      # Validation

app/jobs/
  └── nppes_update_job.rb        # Background job

lib/tasks/
  └── nppes.rake                 # All rake tasks

lib/scripts/
  └── extract_sample_nppes.rb    # Sample extraction

db/
  └── staging_providers.sql      # Staging table schema

# Documentation
NPPES.md                         # NPPES data reference
NPPES_IMPORT_STRATEGY.md        # Detailed strategy
NPPES_IMPORT_README.md          # Complete guide
NPPES_COMMANDS_CHEATSHEET.md    # This file
```

---

## Resources

- **NPPES Download:** https://download.cms.gov/nppes/NPI_Files.html
- **CMS NPI Registry:** https://npiregistry.cms.hhs.gov/
- **Taxonomy Codes:** https://taxonomy.nucc.org/

---

## Quick Status Check

```bash
# One-liner to check everything
rails runner "
  puts 'Providers: ' + Provider.count.to_s
  puts 'Active: ' + Provider.where(deactivation_date: nil).count.to_s
  puts 'Addresses: ' + Address.count.to_s
  puts 'Search: ' + Provider.search_by_name('Smith').count.to_s
  result = NppesHealthCheck.verify_import_health
  puts 'Health: ' + result[:status].upcase
"
```

---

**For full documentation, see:** `NPPES_IMPORT_README.md`
