# NPPES Data Import - Quick Start Guide

This guide covers how to import and maintain NPPES healthcare provider data in your Provider Directory application.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Testing with Sample Data](#testing-with-sample-data)
- [Full Import](#full-import)
- [Weekly Updates](#weekly-updates)
- [Validation](#validation)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

---

## Overview

The NPPES import system uses a **blue-green deployment** strategy for near-zero downtime updates:

- **Initial import:** ~20-40 minutes for 9M records
- **Downtime:** <1 second (just table swap)
- **Weekly updates:** 10-30 minutes in background
- **Storage required:** ~100 GB disk space

### Architecture

```
CSV File (6+ GB)
    ↓
PostgreSQL COPY → Staging Table (~5-10 min)
    ↓
SQL Transformation → Normalized Tables (~15-25 min)
    ↓
Validation & Health Checks (~2-5 min)
    ↓
Atomic Table Swap (<1 second downtime)
    ↓
Production Ready
```

---

## Quick Start

### Prerequisites

1. **PostgreSQL installed** with provider_directory database
2. **Database migrated:** `rails db:migrate`
3. **States seeded:** States should be populated (run `rails db:seed` if not)
4. **Taxonomies seeded:** Common healthcare taxonomies should be present
5. **Disk space:** At least 100 GB available

### 1. Testing with Sample Data (Recommended First Step)

Before importing 9 million records, test with a smaller dataset:

```bash
# Option A: Create sample from full file (if you have it)
ruby lib/scripts/extract_sample_nppes.rb /path/to/npidata.csv /tmp/sample_10k.csv 10000

# Option B: Download a small subset manually from NPPES API
# (Use the CMS NPI Registry API to get sample records)

# Import the sample
rails nppes:import[/tmp/sample_10k.csv]
```

**Expected output:**
```
======================================================================
NPPES DATA IMPORT
======================================================================
CSV File: /tmp/sample_10k.csv
File Size: 15.23 MB
Started: 2025-01-06 10:30:00
======================================================================

[1/4] Creating staging table...
  ✓ Staging table created in 0.2s

[1/4] Loading CSV into staging table...
  ✓ Loaded 10,000 records in 2.1s
  ✓ Average: 4,761 records/second

[2/4] Transforming data into normalized tables...
  ✓ Created new tables
  ✓ Imported 10,000 providers in 3.5s
  ✓ Imported 18,500 addresses in 2.1s
  ✓ Imported 12,300 provider-taxonomy relationships in 4.2s
  ✓ Imported 8,100 identifiers in 3.8s
  ✓ Imported 1,200 authorized officials in 0.5s
  ✓ Updated search indexes and statistics in 1.2s
  ✓ Data transformation complete

[3/4] Validating imported data...
  ✓ Providers: 10,000 records
  ✓ Addresses: 18,500 records
  ✓ Taxonomies: 12,300 records
  ✓ Identifiers: 8,100 records
  ✓ Authorized Officials: 1,200 records
  ✓ No orphaned addresses
  ✓ No orphaned provider taxonomies
  ✓ No duplicate primary taxonomies

[4/4] Swapping tables (minimal downtime)...
  ✓ Tables swapped successfully
  ✓ Old tables cleaned up

[5/5] Cleaning up...
  ✓ Staging table dropped

======================================================================
IMPORT SUMMARY
======================================================================
Providers                     :               10,000
Individual Providers          :                8,000
Organizations                 :                2,000
Active Providers              :                9,850
Deactivated Providers         :                  150

Addresses                     :               18,500
Location Addresses            :                9,800
Mailing Addresses             :                8,700

Provider Taxonomies           :               12,300
Primary Taxonomies            :                9,900

Identifiers                   :                8,100
Authorized Officials          :                1,200
======================================================================

✓ IMPORT COMPLETE
======================================================================
Total Time: 17.6s (0.3 minutes)
Completed: 2025-01-06 10:30:18
======================================================================
```

### 2. Validate the Import

```bash
rails nppes:validate
```

**Expected output:**
```
======================================================================
NPPES DATA VALIDATION
======================================================================

Status: HEALTHY

Checks:
  ✓ Sufficient providers
  ✓ Sufficient addresses
  ✓ Sufficient taxonomies
  ✓ Primary taxonomies exist
  ✓ Search index exists
  ✓ No orphaned addresses
  ✓ No orphaned taxonomies
  ✓ No duplicate npis
  ✓ No multiple primary taxonomies
  ✓ States seeded
  ✓ Taxonomies seeded

✓ All checks passed
```

### 3. View Statistics

```bash
rails nppes:stats
```

### 4. Test the Application

```bash
rails server
# Visit http://localhost:3000
# Search for providers to verify data loaded correctly
```

---

## Full Import

Once you've tested with sample data, you're ready for the full import.

### Step 1: Download NPPES Data

**Option A: Manual Download**

1. Visit https://download.cms.gov/nppes/NPI_Files.html
2. Download "NPPES Data Dissemination" file (6+ GB ZIP)
3. Extract the ZIP file

**Option B: Command Line**

```bash
# Open download page
rails nppes:download

# After manual download, extract:
rails nppes:extract[/path/to/nppes_download.zip,/tmp/nppes_extracted]
```

### Step 2: Run Full Import

```bash
# Recommended: Run during off-peak hours
rails nppes:import[/path/to/npidata_pfile_20250101.csv]
```

**Expected duration:** 20-40 minutes for ~9 million records

**Performance tips:**
- Run on server with SSD for better I/O
- Ensure PostgreSQL has sufficient shared_buffers (at least 2GB)
- Monitor disk space during import

### Step 3: Validate

```bash
rails nppes:validate
rails nppes:stats
```

---

## Weekly Updates

NPPES provides weekly incremental update files with only changed records (typically 50K-200K records).

### Automatic Updates (Recommended)

```bash
# Download weekly update file from CMS
# Then run:
rails nppes:update[/path/to/weekly_update.csv]
```

**This will:**
- Queue a background job (if Sidekiq is configured)
- Update existing providers
- Create new providers
- Sync related data (addresses, taxonomies, etc.)
- **No downtime** - updates happen in background

**Expected duration:** 10-30 minutes

### Manual/Synchronous Updates

If Sidekiq is not configured, updates run synchronously:

```bash
NPPES_UPDATE_CSV_PATH=/path/to/update.csv rails nppes:update
```

### Update Schedule Recommendations

**Option 1: Monthly Full Refresh** (Simpler, recommended initially)
- Every 30 days: Full import from monthly file
- Blue-green swap ensures <1 second downtime
- No drift, always clean data

**Option 2: Weekly Incremental + Quarterly Full** (More complex, fresher data)
- Weekly: Apply incremental updates
- Quarterly: Full refresh to prevent drift

---

## Validation

### Health Checks

```bash
# Quick validation
rails nppes:validate

# Detailed report
rails runner "NppesHealthCheck.detailed_report"
```

### Common Validation Checks

- ✓ Sufficient provider count (>8M for full import)
- ✓ Most providers have addresses (>80%)
- ✓ Most providers have taxonomies (>80%)
- ✓ Search indexes exist
- ✓ No orphaned records
- ✓ No duplicate NPIs
- ✓ States and taxonomies are seeded

### Finding Data Quality Issues

```ruby
# In Rails console
issues = NppesHealthCheck.find_data_quality_issues
issues.each { |issue| puts "⚠ #{issue}" }
```

---

## Troubleshooting

### Problem: Import Fails with "Out of Memory"

**Solution:**
```bash
# Reduce batch size in NppesImporter
# Or add more RAM to server
# Minimum recommended: 4 GB RAM
```

### Problem: Disk Full During Import

**Solution:**
- Ensure 100+ GB free disk space
- Delete old staging tables: `DROP TABLE IF EXISTS staging_providers`
- Clean up old _old tables manually if needed

### Problem: Duplicate NPI Errors

**Solution:**
```sql
-- Find duplicates
SELECT npi, COUNT(*) FROM providers GROUP BY npi HAVING COUNT(*) > 1;

-- Remove duplicates (keep first occurrence)
DELETE FROM providers WHERE id NOT IN (
  SELECT MIN(id) FROM providers GROUP BY npi
);
```

### Problem: Import Takes Too Long

**Possible causes:**
- Slow disk I/O (use SSD)
- Insufficient PostgreSQL configuration
- Network file system (NFS) - copy file locally first

**Solutions:**
```bash
# Check PostgreSQL settings
# In postgresql.conf:
shared_buffers = 2GB
work_mem = 256MB
maintenance_work_mem = 1GB
effective_cache_size = 8GB
```

### Problem: Foreign Key Violations

**Cause:** Missing states or taxonomies

**Solution:**
```bash
# Ensure states are seeded
rails db:seed

# Check states
rails runner "puts State.count"  # Should be 56

# Check taxonomies
rails runner "puts Taxonomy.count"  # Should be 40+
```

### Problem: Search Not Working After Import

**Solution:**
```sql
-- Rebuild search index
REINDEX INDEX index_providers_on_search_vector;

-- Update statistics
ANALYZE providers;
```

---

## Rollback

If an import fails or data is corrupted:

```bash
rails nppes:rollback
```

**This will:**
1. Drop failed/corrupted tables
2. Restore previous data from `_old` tables
3. Complete in <1 second

**Note:** Only works if old tables still exist (within ~5 minutes of swap)

---

## Advanced Usage

### Custom Import with Filters

```ruby
# Import only active providers from specific state
# Modify NppesImporter.import_providers to add WHERE clause:

WHERE npi IS NOT NULL
  AND TRIM(npi) != ''
  AND deactivation_date IS NULL  -- Only active
  AND practice_state = 'CA'      -- Only California
```

### Import Statistics by State

```ruby
# In Rails console
results = NppesHealthCheck.count_providers_by_state
results.each_row do |row|
  puts "#{row['code']}: #{row['provider_count']} providers"
end
```

### Import Statistics by Taxonomy

```ruby
# In Rails console
results = NppesHealthCheck.count_providers_by_taxonomy
results.each_row do |row|
  puts "#{row['code']} - #{row['specialization']}: #{row['provider_count']}"
end
```

### Extracting Sample Data with Filters

```ruby
# Create script lib/scripts/extract_california_sample.rb
# Filter for specific state or taxonomy during extraction
```

---

## File Structure

```
app/
  jobs/
    nppes_update_job.rb          # Background job for updates
  services/
    nppes_importer.rb            # Main import logic
    nppes_update_worker.rb       # Update processing
    nppes_health_check.rb        # Validation checks

db/
  staging_providers.sql          # Staging table schema

lib/
  tasks/
    nppes.rake                   # Rake tasks
  scripts/
    extract_sample_nppes.rb      # Sample extraction tool
```

---

## Performance Benchmarks

Based on typical server (4 CPU, 16GB RAM, SSD):

| Operation | Records | Duration | Rate |
|-----------|---------|----------|------|
| CSV → Staging (COPY) | 9M | 5-10 min | ~20K/sec |
| Staging → Providers | 9M | 3-5 min | ~40K/sec |
| Staging → Addresses | 16M | 2-4 min | ~80K/sec |
| Staging → Taxonomies | 12M | 10-15 min | ~15K/sec |
| Staging → Identifiers | 25M | 15-20 min | ~25K/sec |
| Table Swap | - | <1 sec | - |
| **Total** | **9M** | **20-40 min** | - |

---

## Resources

- **NPPES Download:** https://download.cms.gov/nppes/NPI_Files.html
- **NPPES Documentation:** See `NPPES.md`
- **Import Strategy:** See `NPPES_IMPORT_STRATEGY.md`
- **Database Schema:** See `DATABASE_SCHEMA.md`

---

## Support

If you encounter issues:

1. Check logs: `log/production.log` or `log/development.log`
2. Run validation: `rails nppes:validate`
3. Check data quality: `NppesHealthCheck.detailed_report`
4. Review import strategy document for troubleshooting

---

## Summary of Available Commands

```bash
# Testing
ruby lib/scripts/extract_sample_nppes.rb SOURCE DEST COUNT
rails nppes:import[/path/to/sample.csv]

# Full Import
rails nppes:download                    # Opens download page
rails nppes:extract[zip_path]          # Extract ZIP file
rails nppes:import[csv_path]           # Full import

# Updates
rails nppes:update[csv_path]           # Weekly incremental update

# Validation
rails nppes:validate                    # Quick health check
rails nppes:stats                       # View statistics
rails runner "NppesHealthCheck.detailed_report"

# Maintenance
rails nppes:rollback                    # Rollback failed import
```

---

## Next Steps

1. ✓ Test with sample data (10K-100K records)
2. ✓ Validate sample import
3. ✓ Test application with sample data
4. → Download full NPPES file (6+ GB)
5. → Run full import during off-peak hours
6. → Validate full import
7. → Set up weekly update schedule
8. → Monitor and maintain

**Good luck with your NPPES import!** 🎉
