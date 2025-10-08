# NPPES Data Import Strategy

## Executive Summary

This document outlines the strategy for importing and maintaining the NPPES dataset (~9M providers, 6+ GB CSV) into our PostgreSQL provider directory with minimal downtime and efficient update cycles.

**Key Requirements:**
- Initial import of 6+ GB CSV file (~9 million providers)
- Weekly incremental updates
- Zero or near-zero downtime during updates
- Efficient data transformation from flat CSV to normalized schema
- Robust error handling and rollback capability

---

## 1. File Overview & Challenges

### NPPES CSV File Characteristics

| Attribute | Details |
|-----------|---------|
| **File Size** | 6+ GB uncompressed |
| **Total Records** | ~9 million providers |
| **Columns** | ~330 fields |
| **Structure** | Flat (denormalized) with repeating columns |
| **Update Frequency** | Full: Monthly, Incremental: Weekly |
| **Format Issues** | - 15 taxonomy slots (Healthcare Provider Taxonomy Code_1 through _15)<br>- 50 identifier slots (Other Provider Identifier_1 through _50)<br>- Multiple addresses in single row<br>- Cannot be opened in Excel |

### Key Challenges

1. **Volume**: 9 million records require efficient batch processing
2. **Denormalization**: Flat CSV must be transformed into 10 normalized tables
3. **Repeating Columns**: Must unpack up to 15 taxonomies and 50 identifiers per provider
4. **Data Quality**: Self-reported data may have inconsistencies
5. **Downtime**: Cannot interrupt service during updates
6. **Storage**: Need sufficient disk space for CSV + database + temp tables
7. **Processing Time**: Initial import may take hours

---

## 2. Import Architecture Options

### Option A: Direct Rails Import with Active Record

```ruby
require 'csv'

CSV.foreach('npidata.csv', headers: true).with_index do |row, index|
  Provider.transaction do
    provider = Provider.find_or_create_by(npi: row['NPI']) do |p|
      p.entity_type = row['Entity Type Code']
      p.first_name = row['Provider First Name']
      # ... more fields
    end

    # Create addresses, taxonomies, etc.
  end

  puts "Processed #{index + 1} records" if (index + 1) % 10000 == 0
end
```

**Pros:**
- Simple to implement
- Uses familiar ActiveRecord API
- Built-in validations
- Easy to test

**Cons:**
- VERY SLOW (~10-50 records/second = 50+ hours for 9M records)
- High memory usage
- N+1 queries
- Not suitable for production

**Verdict:** ❌ Only for small test imports

---

### Option B: PostgreSQL COPY Command (Recommended)

```ruby
# 1. Transform CSV to temporary staging tables
# 2. Use PostgreSQL COPY for bulk insert
# 3. Process staging data into normalized tables

PG::Connection.exec(<<~SQL)
  COPY staging_providers (npi, entity_type, first_name, ...)
  FROM '/path/to/npidata.csv'
  WITH (FORMAT CSV, HEADER true, DELIMITER ',');
SQL
```

**Pros:**
- EXTREMELY FAST (~10,000-100,000 records/second)
- Low memory footprint
- Native PostgreSQL optimization
- Can process 9M records in 10-30 minutes

**Cons:**
- More complex setup
- Requires direct database access
- Less validation during import
- Need to handle transformations separately

**Verdict:** ✅ Best for initial import and full refreshes

---

### Option C: Hybrid Approach (Recommended for Production)

**Phase 1: Staging Import (COPY)**
- Load raw CSV into staging table using COPY
- Fast and simple

**Phase 2: Transformation (SQL)**
- Transform staging data into normalized tables using SQL
- Leverage PostgreSQL's power for joins and data manipulation

**Phase 3: Validation (Rails)**
- Run validation queries
- Generate import report
- Handle edge cases with Ruby

**Verdict:** ✅ Best balance of speed and safety

---

## 3. Recommended Implementation Strategy

### Architecture: Hybrid Staging + SQL Transformation

```
┌─────────────────┐
│  NPPES CSV File │
│    (6+ GB)      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  PostgreSQL COPY        │
│  → staging_providers    │
│  (Raw CSV, all 330 cols)│
│  Time: ~5-10 minutes    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  SQL Transformation     │
│  Parse repeating cols   │
│  Normalize data         │
│  Time: ~10-20 minutes   │
└────────┬────────────────┘
         │
         ├──────────────────────────┐
         │                          │
         ▼                          ▼
┌─────────────────┐    ┌─────────────────────┐
│  Production     │    │  Validation &       │
│  Tables:        │    │  Reporting (Rails)  │
│  - providers    │    │  - Check counts     │
│  - addresses    │    │  - Validate refs    │
│  - taxonomies   │    │  - Log errors       │
│  - etc.         │    │  Time: ~5 minutes   │
└─────────────────┘    └─────────────────────┘
```

**Total Estimated Time: 20-35 minutes for full import**

---

## 4. Zero-Downtime Update Strategies

### Strategy 1: Blue-Green Table Swap (Recommended)

**Concept:** Build new tables alongside existing ones, then atomic swap

```sql
-- 1. Create _new tables
CREATE TABLE providers_new (LIKE providers INCLUDING ALL);
CREATE TABLE addresses_new (LIKE addresses INCLUDING ALL);
-- ... other tables

-- 2. Import data into _new tables
-- (20-35 minutes, no impact on production)

-- 3. Validate new data
-- Run checks to ensure data quality

-- 4. Atomic swap (within transaction, <1 second downtime)
BEGIN;
  -- Rename old tables to _old
  ALTER TABLE providers RENAME TO providers_old;
  ALTER TABLE addresses RENAME TO addresses_old;
  -- ...

  -- Rename new tables to production
  ALTER TABLE providers_new RENAME TO providers;
  ALTER TABLE addresses_new RENAME TO addresses;
  -- ...
COMMIT;

-- 5. Drop old tables after verification
DROP TABLE providers_old;
DROP TABLE addresses_old;
-- ...
```

**Downtime:** <1 second (just the RENAME operations)

**Pros:**
- Nearly zero downtime
- Easy rollback (just swap names back)
- No data loss risk
- Can validate before switching

**Cons:**
- Requires 2x storage during import
- Slightly complex

**Estimated Storage:**
- Staging table: ~10 GB
- Production tables: ~15 GB
- New tables: ~15 GB
- **Total during import: ~40 GB**

---

### Strategy 2: Incremental Updates (For Weekly Updates)

**Concept:** Apply only changed records from weekly incremental files

```ruby
# Weekly incremental file contains only new/modified records
# Processing steps:

CSV.foreach('weekly_update.csv', headers: true) do |row|
  npi = row['NPI']

  Provider.transaction do
    # UPSERT pattern
    provider = Provider.find_or_initialize_by(npi: npi)

    # Update all fields
    provider.assign_attributes(
      entity_type: row['Entity Type Code'],
      first_name: row['Provider First Name'],
      # ... more fields
      last_updated: row['Last Update Date']
    )

    provider.save!

    # Update related records (addresses, taxonomies, etc.)
    sync_provider_relationships(provider, row)
  end
end
```

**For weekly updates (typically 50K-200K changed records):**
- Use ActiveRecord (acceptable speed for smaller volumes)
- Process in background job (Sidekiq)
- No downtime
- Time: 10-30 minutes

**Pros:**
- Minimal data transfer
- No downtime
- Preserves existing records

**Cons:**
- More complex logic
- Requires tracking what changed
- Can accumulate drift over time

**Recommendation:** Use this for weekly updates, full refresh monthly/quarterly

---

### Strategy 3: Shadow Table with Trigger-Based Sync (Advanced)

**Concept:** Import to shadow table, use database triggers to sync changes

**Too complex for initial implementation** - only consider if updates become problematic

---

## 5. Detailed Implementation Plan

### Phase 1: Staging Table Setup

Create a staging table that mirrors the flat CSV structure:

```sql
CREATE TABLE staging_providers (
  -- Core fields
  npi VARCHAR(10),
  entity_type_code VARCHAR(1),
  replacement_npi VARCHAR(10),
  ein VARCHAR(9),

  -- Organization name
  org_name VARCHAR(300),

  -- Individual name
  last_name VARCHAR(150),
  first_name VARCHAR(150),
  middle_name VARCHAR(150),
  name_prefix VARCHAR(20),
  name_suffix VARCHAR(20),
  credential VARCHAR(100),

  -- Gender and dates
  gender VARCHAR(1),
  enumeration_date DATE,
  last_update_date DATE,
  deactivation_date DATE,
  deactivation_reason VARCHAR(2),
  reactivation_date DATE,

  -- Mailing address
  mail_address_1 VARCHAR(300),
  mail_address_2 VARCHAR(300),
  mail_city VARCHAR(100),
  mail_state VARCHAR(2),
  mail_postal_code VARCHAR(20),
  mail_country VARCHAR(2),
  mail_phone VARCHAR(20),
  mail_fax VARCHAR(20),

  -- Practice location address
  practice_address_1 VARCHAR(300),
  practice_address_2 VARCHAR(300),
  practice_city VARCHAR(100),
  practice_state VARCHAR(2),
  practice_postal_code VARCHAR(20),
  practice_country VARCHAR(2),
  practice_phone VARCHAR(20),
  practice_fax VARCHAR(20),

  -- Authorized official (for organizations)
  ao_last_name VARCHAR(150),
  ao_first_name VARCHAR(150),
  ao_middle_name VARCHAR(150),
  ao_title VARCHAR(100),
  ao_phone VARCHAR(20),
  ao_prefix VARCHAR(20),
  ao_suffix VARCHAR(20),
  ao_credential VARCHAR(100),

  -- Business details
  sole_proprietor VARCHAR(1),
  org_subpart VARCHAR(1),
  parent_org_lbn VARCHAR(300),
  parent_org_tin VARCHAR(9),

  -- Taxonomies (15 sets of 4 fields each)
  taxonomy_code_1 VARCHAR(10),
  taxonomy_license_1 VARCHAR(100),
  taxonomy_state_1 VARCHAR(2),
  taxonomy_primary_1 VARCHAR(1),

  taxonomy_code_2 VARCHAR(10),
  taxonomy_license_2 VARCHAR(100),
  taxonomy_state_2 VARCHAR(2),
  taxonomy_primary_2 VARCHAR(1),

  -- ... taxonomy_code_3 through taxonomy_code_15 ...

  -- Other identifiers (50 sets of 4 fields each)
  identifier_1 VARCHAR(100),
  identifier_type_1 VARCHAR(2),
  identifier_state_1 VARCHAR(2),
  identifier_issuer_1 VARCHAR(300),

  identifier_2 VARCHAR(100),
  identifier_type_2 VARCHAR(2),
  identifier_state_2 VARCHAR(2),
  identifier_issuer_2 VARCHAR(300)

  -- ... identifier_3 through identifier_50 ...
);
```

### Phase 2: CSV Import Script

**File: `lib/tasks/nppes_import.rake`**

```ruby
namespace :nppes do
  desc "Import NPPES data from CSV file"
  task :import, [:csv_path] => :environment do |t, args|
    csv_path = args[:csv_path] || ENV['NPPES_CSV_PATH']

    raise "CSV file not found: #{csv_path}" unless File.exist?(csv_path)

    puts "Starting NPPES import from: #{csv_path}"
    puts "File size: #{File.size(csv_path) / 1024 / 1024} MB"

    # Record start time
    start_time = Time.current

    # Create staging table
    ActiveRecord::Base.connection.execute(File.read('db/staging_providers.sql'))

    # Import CSV using PostgreSQL COPY
    puts "\n[1/4] Loading CSV into staging table..."
    copy_start = Time.current

    ActiveRecord::Base.connection.raw_connection.copy_data(<<~SQL) do
      COPY staging_providers
      FROM STDIN
      WITH (FORMAT CSV, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8')
    SQL
      File.open(csv_path, 'r') do |file|
        while line = file.gets
          ActiveRecord::Base.connection.raw_connection.put_copy_data(line)
        end
      end
    end

    copy_duration = Time.current - copy_start
    staging_count = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) FROM staging_providers"
    ).first['count']

    puts "✓ Loaded #{staging_count.to_i.to_s(:delimited)} records in #{copy_duration.round(1)}s"

    # Transform data
    puts "\n[2/4] Transforming data into normalized tables..."
    NppesImporter.transform_staging_data

    # Validate
    puts "\n[3/4] Validating imported data..."
    NppesImporter.validate_import

    # Swap tables
    puts "\n[4/4] Swapping tables (minimal downtime)..."
    NppesImporter.swap_tables

    # Cleanup
    puts "\nCleaning up..."
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS staging_providers")

    total_duration = Time.current - start_time
    puts "\n✓ Import complete in #{total_duration.round(1)}s (#{(total_duration / 60).round(1)} minutes)"

    # Print summary
    NppesImporter.print_summary
  end
end
```

### Phase 3: Data Transformation Logic

**File: `app/services/nppes_importer.rb`**

```ruby
class NppesImporter
  class << self
    def transform_staging_data
      # Create new tables
      create_new_tables

      # Import providers
      import_providers

      # Import addresses
      import_addresses

      # Import taxonomies
      import_provider_taxonomies

      # Import identifiers
      import_identifiers

      # Import authorized officials
      import_authorized_officials

      # Update search vectors
      update_search_vectors
    end

    private

    def create_new_tables
      tables = %w[providers addresses provider_taxonomies identifiers authorized_officials]

      tables.each do |table|
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{table}_new (LIKE #{table} INCLUDING ALL);
        SQL
      end
    end

    def import_providers
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO providers_new (
          npi, entity_type, first_name, last_name, middle_name,
          name_prefix, name_suffix, credential, gender,
          organization_name, sole_proprietor, org_subpart,
          enumeration_date, deactivation_date, deactivation_reason,
          reactivation_date, created_at, updated_at
        )
        SELECT
          npi,
          CAST(entity_type_code AS INTEGER),
          first_name,
          last_name,
          middle_name,
          name_prefix,
          name_suffix,
          credential,
          CASE
            WHEN gender = 'M' THEN 'M'
            WHEN gender = 'F' THEN 'F'
            WHEN gender = 'X' THEN 'X'
            ELSE NULL
          END,
          org_name,
          CASE WHEN sole_proprietor = 'Y' THEN true ELSE false END,
          CASE WHEN org_subpart = 'Y' THEN true ELSE false END,
          TO_DATE(enumeration_date, 'MM/DD/YYYY'),
          TO_DATE(NULLIF(deactivation_date, ''), 'MM/DD/YYYY'),
          deactivation_reason,
          TO_DATE(NULLIF(reactivation_date, ''), 'MM/DD/YYYY'),
          NOW(),
          NOW()
        FROM staging_providers
        WHERE npi IS NOT NULL;
      SQL

      count = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM providers_new"
      ).first['count']

      puts "  ✓ Imported #{count.to_i.to_s(:delimited)} providers"
    end

    def import_addresses
      # Import mailing addresses
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO addresses_new (
          provider_id, address_purpose, address_1, address_2,
          city_name, postal_code, telephone, fax_number,
          city_id, state_id, created_at, updated_at
        )
        SELECT
          (SELECT id FROM providers_new WHERE providers_new.npi = s.npi),
          'MAILING',
          s.mail_address_1,
          s.mail_address_2,
          s.mail_city,
          s.mail_postal_code,
          s.mail_phone,
          s.mail_fax,
          (SELECT id FROM cities WHERE cities.name = s.mail_city AND cities.state_id = (
            SELECT id FROM states WHERE states.code = s.mail_state
          ) LIMIT 1),
          (SELECT id FROM states WHERE states.code = s.mail_state),
          NOW(),
          NOW()
        FROM staging_providers s
        WHERE s.mail_address_1 IS NOT NULL;
      SQL

      # Import practice location addresses
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO addresses_new (
          provider_id, address_purpose, address_1, address_2,
          city_name, postal_code, telephone, fax_number,
          city_id, state_id, created_at, updated_at
        )
        SELECT
          (SELECT id FROM providers_new WHERE providers_new.npi = s.npi),
          'LOCATION',
          s.practice_address_1,
          s.practice_address_2,
          s.practice_city,
          s.practice_postal_code,
          s.practice_phone,
          s.practice_fax,
          (SELECT id FROM cities WHERE cities.name = s.practice_city AND cities.state_id = (
            SELECT id FROM states WHERE states.code = s.practice_state
          ) LIMIT 1),
          (SELECT id FROM states WHERE states.code = s.practice_state),
          NOW(),
          NOW()
        FROM staging_providers s
        WHERE s.practice_address_1 IS NOT NULL;
      SQL

      count = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM addresses_new"
      ).first['count']

      puts "  ✓ Imported #{count.to_i.to_s(:delimited)} addresses"
    end

    def import_provider_taxonomies
      # Unpack up to 15 taxonomy slots per provider
      15.times do |i|
        slot = i + 1

        ActiveRecord::Base.connection.execute(<<~SQL)
          INSERT INTO provider_taxonomies_new (
            provider_id, taxonomy_id, license_number, license_state_id,
            is_primary, created_at, updated_at
          )
          SELECT
            (SELECT id FROM providers_new WHERE providers_new.npi = s.npi),
            (SELECT id FROM taxonomies WHERE taxonomies.code = s.taxonomy_code_#{slot}),
            s.taxonomy_license_#{slot},
            (SELECT id FROM states WHERE states.code = s.taxonomy_state_#{slot}),
            CASE WHEN s.taxonomy_primary_#{slot} = 'Y' THEN true ELSE false END,
            NOW(),
            NOW()
          FROM staging_providers s
          WHERE s.taxonomy_code_#{slot} IS NOT NULL
            AND s.taxonomy_code_#{slot} != ''
            AND EXISTS (SELECT 1 FROM taxonomies WHERE code = s.taxonomy_code_#{slot});
        SQL
      end

      count = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM provider_taxonomies_new"
      ).first['count']

      puts "  ✓ Imported #{count.to_i.to_s(:delimited)} provider-taxonomy relationships"
    end

    def import_identifiers
      # Unpack up to 50 identifier slots per provider
      50.times do |i|
        slot = i + 1

        ActiveRecord::Base.connection.execute(<<~SQL)
          INSERT INTO identifiers_new (
            provider_id, identifier_type_code, identifier_value,
            state_id, issuer, created_at, updated_at
          )
          SELECT
            (SELECT id FROM providers_new WHERE providers_new.npi = s.npi),
            s.identifier_type_#{slot},
            s.identifier_#{slot},
            (SELECT id FROM states WHERE states.code = s.identifier_state_#{slot}),
            s.identifier_issuer_#{slot},
            NOW(),
            NOW()
          FROM staging_providers s
          WHERE s.identifier_#{slot} IS NOT NULL
            AND s.identifier_#{slot} != '';
        SQL
      end

      count = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM identifiers_new"
      ).first['count']

      puts "  ✓ Imported #{count.to_i.to_s(:delimited)} identifiers"
    end

    def import_authorized_officials
      ActiveRecord::Base.connection.execute(<<~SQL)
        INSERT INTO authorized_officials_new (
          provider_id, first_name, last_name, middle_name,
          title_or_position, telephone, name_prefix, name_suffix,
          credential, created_at, updated_at
        )
        SELECT
          (SELECT id FROM providers_new WHERE providers_new.npi = s.npi),
          s.ao_first_name,
          s.ao_last_name,
          s.ao_middle_name,
          s.ao_title,
          s.ao_phone,
          s.ao_prefix,
          s.ao_suffix,
          s.ao_credential,
          NOW(),
          NOW()
        FROM staging_providers s
        WHERE s.entity_type_code = '2'  -- Organizations only
          AND s.ao_last_name IS NOT NULL;
      SQL

      count = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM authorized_officials_new"
      ).first['count']

      puts "  ✓ Imported #{count.to_i.to_s(:delimited)} authorized officials"
    end

    def update_search_vectors
      # Search vectors are auto-generated, but we can trigger update
      ActiveRecord::Base.connection.execute(<<~SQL)
        -- Search vectors are generated columns, no manual update needed
        -- But we can analyze the table for better query performance
        ANALYZE providers_new;
      SQL

      puts "  ✓ Updated search vectors and statistics"
    end

    def validate_import
      validations = {
        "Providers" => "SELECT COUNT(*) FROM providers_new",
        "Addresses" => "SELECT COUNT(*) FROM addresses_new",
        "Taxonomies" => "SELECT COUNT(*) FROM provider_taxonomies_new",
        "Identifiers" => "SELECT COUNT(*) FROM identifiers_new",
        "Authorized Officials" => "SELECT COUNT(*) FROM authorized_officials_new"
      }

      validations.each do |name, query|
        count = ActiveRecord::Base.connection.execute(query).first['count'].to_i
        puts "  ✓ #{name}: #{count.to_s(:delimited)} records"
      end

      # Validate referential integrity
      orphaned_addresses = ActiveRecord::Base.connection.execute(<<~SQL).first['count'].to_i
        SELECT COUNT(*) FROM addresses_new
        WHERE provider_id NOT IN (SELECT id FROM providers_new)
      SQL

      if orphaned_addresses > 0
        puts "  ⚠ Warning: #{orphaned_addresses} orphaned addresses found"
      else
        puts "  ✓ No orphaned addresses"
      end
    end

    def swap_tables
      tables = %w[providers addresses provider_taxonomies identifiers authorized_officials]

      ActiveRecord::Base.transaction do
        tables.each do |table|
          # Rename old to _old
          ActiveRecord::Base.connection.execute(
            "ALTER TABLE #{table} RENAME TO #{table}_old"
          )

          # Rename new to production
          ActiveRecord::Base.connection.execute(
            "ALTER TABLE #{table}_new RENAME TO #{table}"
          )
        end
      end

      puts "  ✓ Tables swapped successfully"

      # Drop old tables after brief delay
      sleep 5
      tables.each do |table|
        ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{table}_old")
      end

      puts "  ✓ Old tables cleaned up"
    end

    def print_summary
      puts "\n" + "="*60
      puts "IMPORT SUMMARY"
      puts "="*60

      [
        ["Providers", "SELECT COUNT(*) FROM providers"],
        ["Individual Providers", "SELECT COUNT(*) FROM providers WHERE entity_type = 1"],
        ["Organizations", "SELECT COUNT(*) FROM providers WHERE entity_type = 2"],
        ["Addresses", "SELECT COUNT(*) FROM addresses"],
        ["Location Addresses", "SELECT COUNT(*) FROM addresses WHERE address_purpose = 'LOCATION'"],
        ["Mailing Addresses", "SELECT COUNT(*) FROM addresses WHERE address_purpose = 'MAILING'"],
        ["Provider Taxonomies", "SELECT COUNT(*) FROM provider_taxonomies"],
        ["Primary Taxonomies", "SELECT COUNT(*) FROM provider_taxonomies WHERE is_primary = true"],
        ["Identifiers", "SELECT COUNT(*) FROM identifiers"],
        ["Authorized Officials", "SELECT COUNT(*) FROM authorized_officials"]
      ].each do |label, query|
        count = ActiveRecord::Base.connection.execute(query).first['count'].to_i
        puts "#{label.ljust(30)}: #{count.to_s(:delimited).rjust(15)}"
      end

      puts "="*60
    end
  end
end
```

---

## 6. Weekly Incremental Update Strategy

**File: `lib/tasks/nppes_update.rake`**

```ruby
namespace :nppes do
  desc "Apply weekly incremental update"
  task :update, [:csv_path] => :environment do |t, args|
    csv_path = args[:csv_path] || ENV['NPPES_UPDATE_CSV_PATH']

    raise "CSV file not found: #{csv_path}" unless File.exist?(csv_path)

    puts "Starting NPPES incremental update from: #{csv_path}"

    # Use background job for updates to avoid blocking
    NppesUpdateJob.perform_later(csv_path)

    puts "Update job queued. Monitor with Sidekiq dashboard."
  end
end
```

**File: `app/jobs/nppes_update_job.rb`**

```ruby
class NppesUpdateJob < ApplicationJob
  queue_as :default

  def perform(csv_path)
    start_time = Time.current
    updated_count = 0
    created_count = 0
    error_count = 0

    CSV.foreach(csv_path, headers: true).with_index do |row, index|
      begin
        npi = row['NPI']

        Provider.transaction do
          provider = Provider.find_or_initialize_by(npi: npi)
          is_new = provider.new_record?

          # Update provider attributes
          provider.assign_attributes(
            entity_type: row['Entity Type Code'].to_i,
            first_name: row['Provider First Name'],
            last_name: row['Provider Last Name'],
            middle_name: row['Provider Middle Name'],
            credential: row['Provider Credential Text'],
            gender: row['Provider Gender Code'],
            organization_name: row['Provider Organization Name (Legal Business Name)'],
            enumeration_date: parse_date(row['Provider Enumeration Date']),
            deactivation_date: parse_date(row['NPI Deactivation Date']),
            # ... more fields
          )

          provider.save!

          # Sync addresses
          sync_addresses(provider, row)

          # Sync taxonomies
          sync_taxonomies(provider, row)

          # Sync identifiers
          sync_identifiers(provider, row)

          # Sync authorized official (if organization)
          sync_authorized_official(provider, row) if provider.entity_organization?

          if is_new
            created_count += 1
          else
            updated_count += 1
          end
        end
      rescue => e
        error_count += 1
        Rails.logger.error("Error processing NPI #{row['NPI']}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end

      # Progress update every 10,000 records
      if (index + 1) % 10000 == 0
        puts "Processed #{index + 1} records (#{created_count} created, #{updated_count} updated, #{error_count} errors)"
      end
    end

    duration = Time.current - start_time

    puts "\n✓ Update complete in #{duration.round(1)}s (#{(duration / 60).round(1)} minutes)"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Errors: #{error_count}"
  end

  private

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.strptime(date_string, '%m/%d/%Y')
  rescue ArgumentError
    nil
  end

  def sync_addresses(provider, row)
    # Remove existing addresses and recreate
    # (simpler than trying to match and update)
    provider.addresses.destroy_all

    # Mailing address
    if row['Provider First Line Business Mailing Address'].present?
      provider.addresses.create!(
        address_purpose: 'MAILING',
        address_1: row['Provider First Line Business Mailing Address'],
        address_2: row['Provider Second Line Business Mailing Address'],
        city_name: row['Provider Business Mailing Address City Name'],
        postal_code: row['Provider Business Mailing Address Postal Code'],
        telephone: row['Provider Business Mailing Address Telephone Number'],
        fax_number: row['Provider Business Mailing Address Fax Number'],
        state: State.find_by(code: row['Provider Business Mailing Address State Name']),
        city: find_or_create_city(
          row['Provider Business Mailing Address City Name'],
          row['Provider Business Mailing Address State Name']
        )
      )
    end

    # Practice location address
    if row['Provider First Line Business Practice Location Address'].present?
      provider.addresses.create!(
        address_purpose: 'LOCATION',
        address_1: row['Provider First Line Business Practice Location Address'],
        address_2: row['Provider Second Line Business Practice Location Address'],
        city_name: row['Provider Business Practice Location Address City Name'],
        postal_code: row['Provider Business Practice Location Address Postal Code'],
        telephone: row['Provider Business Practice Location Address Telephone Number'],
        fax_number: row['Provider Business Practice Location Address Fax Number'],
        state: State.find_by(code: row['Provider Business Practice Location Address State Name']),
        city: find_or_create_city(
          row['Provider Business Practice Location Address City Name'],
          row['Provider Business Practice Location Address State Name']
        )
      )
    end
  end

  def sync_taxonomies(provider, row)
    provider.provider_taxonomies.destroy_all

    15.times do |i|
      slot = i + 1
      code = row["Healthcare Provider Taxonomy Code_#{slot}"]

      next if code.blank?

      taxonomy = Taxonomy.find_by(code: code)
      next unless taxonomy

      provider.provider_taxonomies.create!(
        taxonomy: taxonomy,
        license_number: row["Provider License Number_#{slot}"],
        license_state: State.find_by(code: row["Provider License Number State Code_#{slot}"]),
        is_primary: row["Healthcare Provider Primary Taxonomy Switch_#{slot}"] == 'Y'
      )
    end
  end

  def sync_identifiers(provider, row)
    provider.identifiers.destroy_all

    50.times do |i|
      slot = i + 1
      identifier_value = row["Other Provider Identifier_#{slot}"]

      next if identifier_value.blank?

      provider.identifiers.create!(
        identifier_type_code: row["Other Provider Identifier Type Code_#{slot}"],
        identifier_value: identifier_value,
        state: State.find_by(code: row["Other Provider Identifier State_#{slot}"]),
        issuer: row["Other Provider Identifier Issuer_#{slot}"]
      )
    end
  end

  def sync_authorized_official(provider, row)
    return if row['Authorized Official Last Name'].blank?

    provider.authorized_official&.destroy

    provider.create_authorized_official!(
      first_name: row['Authorized Official First Name'],
      last_name: row['Authorized Official Last Name'],
      middle_name: row['Authorized Official Middle Name'],
      title_or_position: row['Authorized Official Title or Position'],
      telephone: row['Authorized Official Telephone Number'],
      name_prefix: row['Authorized Official Name Prefix Text'],
      name_suffix: row['Authorized Official Name Suffix Text'],
      credential: row['Authorized Official Credential Text']
    )
  end

  def find_or_create_city(city_name, state_code)
    return nil if city_name.blank? || state_code.blank?

    state = State.find_by(code: state_code)
    return nil unless state

    City.find_or_create_by!(name: city_name, state: state)
  end
end
```

---

## 7. Database Sizing & Performance Estimates

### Storage Requirements

| Component | Size Estimate | Notes |
|-----------|--------------|-------|
| **CSV File** | 6 GB | Uncompressed |
| **Staging Table** | ~10 GB | PostgreSQL storage with indexes |
| **Production Tables** | ~15 GB | Normalized across 10 tables with indexes |
| **Temp Storage (import)** | ~15 GB | New tables during blue-green swap |
| **Total During Import** | ~40 GB | Need headroom for operations |
| **Recommended Disk** | 100 GB+ | Allows for growth and multiple versions |

### Performance Estimates (on modern server)

**Initial Import (9M records):**
- CSV → Staging (COPY): 5-10 minutes
- Staging → Normalized tables (SQL): 15-25 minutes
- Validation: 2-5 minutes
- **Total: 20-40 minutes**

**Weekly Update (50K-200K records):**
- Using ActiveRecord batch processing: 10-30 minutes
- Background job, no downtime

**Table Swap:**
- Downtime: <1 second (just ALTER TABLE RENAME)

**Search Performance:**
- Full-text search: 50-200ms for typical queries
- NPI lookup: <10ms (indexed)
- Geographic filtering: 100-300ms

---

## 8. Monitoring & Rollback

### Health Checks During Import

```ruby
# File: app/services/nppes_health_check.rb

class NppesHealthCheck
  def self.verify_import_health
    checks = {
      provider_count: -> { Provider.count > 8_000_000 }, # Should have at least 8M providers
      address_count: -> { Address.count > 10_000_000 },  # Should have addresses
      taxonomy_count: -> { ProviderTaxonomy.count > 9_000_000 }, # Most providers have taxonomies
      primary_taxonomy_exists: -> {
        ProviderTaxonomy.where(is_primary: true).count > 8_000_000
      },
      search_index_exists: -> {
        ActiveRecord::Base.connection.execute(
          "SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'index_providers_on_search_vector'"
        ).first['count'].to_i > 0
      },
      foreign_keys_valid: -> {
        # Check no orphaned addresses
        Address.where.not(provider_id: Provider.select(:id)).count == 0
      }
    }

    results = {}
    checks.each do |name, check|
      results[name] = check.call
    end

    all_pass = results.values.all?

    {
      status: all_pass ? 'healthy' : 'unhealthy',
      checks: results
    }
  end
end
```

### Rollback Strategy

**If import fails or data is corrupted:**

```sql
BEGIN;
  -- Swap back to old tables
  ALTER TABLE providers RENAME TO providers_failed;
  ALTER TABLE addresses RENAME TO addresses_failed;
  ALTER TABLE provider_taxonomies RENAME TO provider_taxonomies_failed;
  ALTER TABLE identifiers RENAME TO identifiers_failed;
  ALTER TABLE authorized_officials RENAME TO authorized_officials_failed;

  -- Restore old tables
  ALTER TABLE providers_old RENAME TO providers;
  ALTER TABLE addresses_old RENAME TO addresses;
  ALTER TABLE provider_taxonomies_old RENAME TO provider_taxonomies;
  ALTER TABLE identifiers_old RENAME TO identifiers;
  ALTER TABLE authorized_officials_old RENAME TO authorized_officials;
COMMIT;

-- Service restored in <1 second
```

---

## 9. Recommended Schedule

### Initial Setup
1. **Development Testing**
   - Import sample CSV (first 100K records) for testing
   - Verify transformations work correctly
   - Time: 1-2 days

2. **Staging Full Import**
   - Import full 9M record dataset on staging server
   - Validate data quality
   - Performance tuning
   - Time: 1-2 days

3. **Production Initial Import**
   - Schedule during low-traffic window
   - Use blue-green swap for minimal downtime
   - Time: 30-60 minutes

### Ongoing Maintenance

**Option A: Monthly Full Refresh** (Recommended to start)
- Every 30 days, do full re-import from monthly file
- Blue-green swap ensures <1 second downtime
- Simple, no drift, always clean data

**Option B: Weekly Incremental + Quarterly Full**
- Weekly: Apply incremental updates (50K-200K records)
- Quarterly: Full refresh to prevent drift
- More complex but fresher data

**Recommendation:** Start with Option A, migrate to Option B if weekly freshness becomes critical

---

## 10. Sample Commands

### Initial Import
```bash
# Download NPPES file
wget https://download.cms.gov/nppes/NPPES_Data_Dissemination_MMDDYYYY.zip
unzip NPPES_Data_Dissemination_MMDDYYYY.zip

# Import to database
rails nppes:import[/path/to/npidata_pfile_20250101-20250107.csv]
```

### Weekly Update
```bash
# Download weekly incremental file
wget https://download.cms.gov/nppes/NPPES_Deactivated_NPI_Report_MMDDYYYY.zip

# Apply update (runs in background)
rails nppes:update[/path/to/weekly_update.csv]
```

### Validate Data
```ruby
# In Rails console
NppesHealthCheck.verify_import_health
# => { status: 'healthy', checks: { ... } }
```

---

## 11. Error Handling

### Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| **Out of memory** | Processing too many records at once | Batch processing in chunks |
| **Disk full** | Insufficient storage | Ensure 100GB+ available |
| **Foreign key violations** | Missing state or taxonomy | Pre-seed all states and common taxonomies |
| **Duplicate NPIs** | Data quality issue | Use `ON CONFLICT DO UPDATE` in PostgreSQL |
| **Encoding errors** | UTF-8 vs Latin-1 | Specify `ENCODING 'UTF8'` in COPY command |
| **Date parse errors** | Invalid date formats | Use `TO_DATE` with `NULLIF` for blank dates |
| **Timeout during swap** | Long transaction | Ensure no active queries during swap window |

---

## 12. Next Steps

### To Implement This Strategy:

1. **Review and approve this document**
2. **Create staging table SQL** (`db/staging_providers.sql`)
3. **Implement `NppesImporter` service** (`app/services/nppes_importer.rb`)
4. **Create rake tasks** (`lib/tasks/nppes_import.rake`, `lib/tasks/nppes_update.rake`)
5. **Create update job** (`app/jobs/nppes_update_job.rb`)
6. **Test with sample data** (first 10K-100K records)
7. **Staging environment full test** (full 9M records)
8. **Production deployment**

### Questions to Resolve:

- [ ] What is acceptable downtime for initial import? (Recommend off-hours)
- [ ] Do we need weekly updates or is monthly sufficient?
- [ ] What background job system to use? (Sidekiq recommended)
- [ ] Should we import ALL 9M providers or filter by active status?
- [ ] Do we need to handle deactivated providers specially?
- [ ] Should we implement automatic scheduled imports or manual trigger?

---

## Summary

**Recommended Approach:**
- **Staging + SQL transformation** for initial import and monthly refreshes
- **Blue-green table swap** for zero-downtime deployment
- **ActiveRecord batch processing** for weekly incremental updates
- **Health checks and rollback** strategy for safety

**Expected Performance:**
- Initial import: 20-40 minutes
- Downtime during swap: <1 second
- Weekly updates: 10-30 minutes (background, no downtime)
- Storage required: 100 GB disk space

**Key Benefits:**
- Minimal complexity
- Near-zero downtime
- Easy to rollback
- Scalable to 9M+ records
- Maintainable by Rails developers
