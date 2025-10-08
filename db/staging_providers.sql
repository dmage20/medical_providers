-- Staging table for NPPES CSV import
-- This table mirrors the flat structure of the NPPES CSV file (~330 columns)
-- Data will be imported here via PostgreSQL COPY, then transformed into normalized tables

DROP TABLE IF EXISTS staging_providers;

CREATE TABLE staging_providers (
  -- ============================================================
  -- CORE IDENTIFICATION (Columns 1-15)
  -- ============================================================
  npi VARCHAR(10),
  entity_type_code VARCHAR(1),                -- 1 = Individual, 2 = Organization
  replacement_npi VARCHAR(10),
  ein VARCHAR(9),                             -- Employer Identification Number

  -- Organization name
  org_name VARCHAR(300),                      -- Legal Business Name

  -- Individual name
  last_name VARCHAR(150),
  first_name VARCHAR(150),
  middle_name VARCHAR(150),
  name_prefix VARCHAR(20),
  name_suffix VARCHAR(20),
  credential VARCHAR(100),                    -- MD, DO, NP, PA, etc.

  -- Other organization name
  other_org_name VARCHAR(300),
  other_org_name_type_code VARCHAR(2),

  -- Other individual name
  other_last_name VARCHAR(150),
  other_first_name VARCHAR(150),

  -- ============================================================
  -- OTHER NAMES / FORMER NAMES (Columns 16-24)
  -- ============================================================
  other_middle_name VARCHAR(150),
  other_name_prefix VARCHAR(20),
  other_name_suffix VARCHAR(20),
  other_credential VARCHAR(100),
  other_last_name_type_code VARCHAR(2),

  -- ============================================================
  -- BUSINESS MAILING ADDRESS (Columns 25-32)
  -- ============================================================
  mail_address_1 VARCHAR(300),
  mail_address_2 VARCHAR(300),
  mail_city VARCHAR(100),
  mail_state VARCHAR(2),
  mail_postal_code VARCHAR(20),
  mail_country VARCHAR(2),
  mail_phone VARCHAR(20),
  mail_fax VARCHAR(20),

  -- ============================================================
  -- BUSINESS PRACTICE LOCATION ADDRESS (Columns 33-40)
  -- ============================================================
  practice_address_1 VARCHAR(300),
  practice_address_2 VARCHAR(300),
  practice_city VARCHAR(100),
  practice_state VARCHAR(2),
  practice_postal_code VARCHAR(20),
  practice_country VARCHAR(2),
  practice_phone VARCHAR(20),
  practice_fax VARCHAR(20),

  -- ============================================================
  -- ENUMERATION INFORMATION (Columns 41-46)
  -- ============================================================
  enumeration_date VARCHAR(10),               -- MM/DD/YYYY format
  last_update_date VARCHAR(10),               -- MM/DD/YYYY format
  deactivation_reason VARCHAR(2),
  deactivation_date VARCHAR(10),              -- MM/DD/YYYY format
  reactivation_date VARCHAR(10),              -- MM/DD/YYYY format
  gender VARCHAR(1),                          -- M, F, or blank

  -- ============================================================
  -- AUTHORIZED OFFICIAL (for Organizations) (Columns 47-55)
  -- ============================================================
  ao_last_name VARCHAR(150),
  ao_first_name VARCHAR(150),
  ao_middle_name VARCHAR(150),
  ao_title VARCHAR(100),
  ao_phone VARCHAR(20),
  ao_prefix VARCHAR(20),
  ao_suffix VARCHAR(20),
  ao_credential VARCHAR(100),

  -- ============================================================
  -- CERTIFICATION / BUSINESS DETAILS (Columns 56-59)
  -- ============================================================
  sole_proprietor VARCHAR(1),                 -- Y or N
  org_subpart VARCHAR(1),                     -- Y or N
  parent_org_lbn VARCHAR(300),
  parent_org_tin VARCHAR(9),

  -- ============================================================
  -- HEALTHCARE PROVIDER TAXONOMIES (15 slots × 4 fields = 60 columns)
  -- Columns 60-119
  -- ============================================================
  taxonomy_code_1 VARCHAR(10),
  taxonomy_license_1 VARCHAR(100),
  taxonomy_state_1 VARCHAR(2),
  taxonomy_primary_1 VARCHAR(1),              -- Y or N

  taxonomy_code_2 VARCHAR(10),
  taxonomy_license_2 VARCHAR(100),
  taxonomy_state_2 VARCHAR(2),
  taxonomy_primary_2 VARCHAR(1),

  taxonomy_code_3 VARCHAR(10),
  taxonomy_license_3 VARCHAR(100),
  taxonomy_state_3 VARCHAR(2),
  taxonomy_primary_3 VARCHAR(1),

  taxonomy_code_4 VARCHAR(10),
  taxonomy_license_4 VARCHAR(100),
  taxonomy_state_4 VARCHAR(2),
  taxonomy_primary_4 VARCHAR(1),

  taxonomy_code_5 VARCHAR(10),
  taxonomy_license_5 VARCHAR(100),
  taxonomy_state_5 VARCHAR(2),
  taxonomy_primary_5 VARCHAR(1),

  taxonomy_code_6 VARCHAR(10),
  taxonomy_license_6 VARCHAR(100),
  taxonomy_state_6 VARCHAR(2),
  taxonomy_primary_6 VARCHAR(1),

  taxonomy_code_7 VARCHAR(10),
  taxonomy_license_7 VARCHAR(100),
  taxonomy_state_7 VARCHAR(2),
  taxonomy_primary_7 VARCHAR(1),

  taxonomy_code_8 VARCHAR(10),
  taxonomy_license_8 VARCHAR(100),
  taxonomy_state_8 VARCHAR(2),
  taxonomy_primary_8 VARCHAR(1),

  taxonomy_code_9 VARCHAR(10),
  taxonomy_license_9 VARCHAR(100),
  taxonomy_state_9 VARCHAR(2),
  taxonomy_primary_9 VARCHAR(1),

  taxonomy_code_10 VARCHAR(10),
  taxonomy_license_10 VARCHAR(100),
  taxonomy_state_10 VARCHAR(2),
  taxonomy_primary_10 VARCHAR(1),

  taxonomy_code_11 VARCHAR(10),
  taxonomy_license_11 VARCHAR(100),
  taxonomy_state_11 VARCHAR(2),
  taxonomy_primary_11 VARCHAR(1),

  taxonomy_code_12 VARCHAR(10),
  taxonomy_license_12 VARCHAR(100),
  taxonomy_state_12 VARCHAR(2),
  taxonomy_primary_12 VARCHAR(1),

  taxonomy_code_13 VARCHAR(10),
  taxonomy_license_13 VARCHAR(100),
  taxonomy_state_13 VARCHAR(2),
  taxonomy_primary_13 VARCHAR(1),

  taxonomy_code_14 VARCHAR(10),
  taxonomy_license_14 VARCHAR(100),
  taxonomy_state_14 VARCHAR(2),
  taxonomy_primary_14 VARCHAR(1),

  taxonomy_code_15 VARCHAR(10),
  taxonomy_license_15 VARCHAR(100),
  taxonomy_state_15 VARCHAR(2),
  taxonomy_primary_15 VARCHAR(1),

  -- ============================================================
  -- OTHER PROVIDER IDENTIFIERS (50 slots × 4 fields = 200 columns)
  -- Columns 120-319
  -- ============================================================
  identifier_1 VARCHAR(100),
  identifier_type_1 VARCHAR(2),
  identifier_state_1 VARCHAR(2),
  identifier_issuer_1 VARCHAR(300),

  identifier_2 VARCHAR(100),
  identifier_type_2 VARCHAR(2),
  identifier_state_2 VARCHAR(2),
  identifier_issuer_2 VARCHAR(300),

  identifier_3 VARCHAR(100),
  identifier_type_3 VARCHAR(2),
  identifier_state_3 VARCHAR(2),
  identifier_issuer_3 VARCHAR(300),

  identifier_4 VARCHAR(100),
  identifier_type_4 VARCHAR(2),
  identifier_state_4 VARCHAR(2),
  identifier_issuer_4 VARCHAR(300),

  identifier_5 VARCHAR(100),
  identifier_type_5 VARCHAR(2),
  identifier_state_5 VARCHAR(2),
  identifier_issuer_5 VARCHAR(300),

  identifier_6 VARCHAR(100),
  identifier_type_6 VARCHAR(2),
  identifier_state_6 VARCHAR(2),
  identifier_issuer_6 VARCHAR(300),

  identifier_7 VARCHAR(100),
  identifier_type_7 VARCHAR(2),
  identifier_state_7 VARCHAR(2),
  identifier_issuer_7 VARCHAR(300),

  identifier_8 VARCHAR(100),
  identifier_type_8 VARCHAR(2),
  identifier_state_8 VARCHAR(2),
  identifier_issuer_8 VARCHAR(300),

  identifier_9 VARCHAR(100),
  identifier_type_9 VARCHAR(2),
  identifier_state_9 VARCHAR(2),
  identifier_issuer_9 VARCHAR(300),

  identifier_10 VARCHAR(100),
  identifier_type_10 VARCHAR(2),
  identifier_state_10 VARCHAR(2),
  identifier_issuer_10 VARCHAR(300),

  identifier_11 VARCHAR(100),
  identifier_type_11 VARCHAR(2),
  identifier_state_11 VARCHAR(2),
  identifier_issuer_11 VARCHAR(300),

  identifier_12 VARCHAR(100),
  identifier_type_12 VARCHAR(2),
  identifier_state_12 VARCHAR(2),
  identifier_issuer_12 VARCHAR(300),

  identifier_13 VARCHAR(100),
  identifier_type_13 VARCHAR(2),
  identifier_state_13 VARCHAR(2),
  identifier_issuer_13 VARCHAR(300),

  identifier_14 VARCHAR(100),
  identifier_type_14 VARCHAR(2),
  identifier_state_14 VARCHAR(2),
  identifier_issuer_14 VARCHAR(300),

  identifier_15 VARCHAR(100),
  identifier_type_15 VARCHAR(2),
  identifier_state_15 VARCHAR(2),
  identifier_issuer_15 VARCHAR(300),

  identifier_16 VARCHAR(100),
  identifier_type_16 VARCHAR(2),
  identifier_state_16 VARCHAR(2),
  identifier_issuer_16 VARCHAR(300),

  identifier_17 VARCHAR(100),
  identifier_type_17 VARCHAR(2),
  identifier_state_17 VARCHAR(2),
  identifier_issuer_17 VARCHAR(300),

  identifier_18 VARCHAR(100),
  identifier_type_18 VARCHAR(2),
  identifier_state_18 VARCHAR(2),
  identifier_issuer_18 VARCHAR(300),

  identifier_19 VARCHAR(100),
  identifier_type_19 VARCHAR(2),
  identifier_state_19 VARCHAR(2),
  identifier_issuer_19 VARCHAR(300),

  identifier_20 VARCHAR(100),
  identifier_type_20 VARCHAR(2),
  identifier_state_20 VARCHAR(2),
  identifier_issuer_20 VARCHAR(300),

  identifier_21 VARCHAR(100),
  identifier_type_21 VARCHAR(2),
  identifier_state_21 VARCHAR(2),
  identifier_issuer_21 VARCHAR(300),

  identifier_22 VARCHAR(100),
  identifier_type_22 VARCHAR(2),
  identifier_state_22 VARCHAR(2),
  identifier_issuer_22 VARCHAR(300),

  identifier_23 VARCHAR(100),
  identifier_type_23 VARCHAR(2),
  identifier_state_23 VARCHAR(2),
  identifier_issuer_23 VARCHAR(300),

  identifier_24 VARCHAR(100),
  identifier_type_24 VARCHAR(2),
  identifier_state_24 VARCHAR(2),
  identifier_issuer_24 VARCHAR(300),

  identifier_25 VARCHAR(100),
  identifier_type_25 VARCHAR(2),
  identifier_state_25 VARCHAR(2),
  identifier_issuer_25 VARCHAR(300),

  identifier_26 VARCHAR(100),
  identifier_type_26 VARCHAR(2),
  identifier_state_26 VARCHAR(2),
  identifier_issuer_26 VARCHAR(300),

  identifier_27 VARCHAR(100),
  identifier_type_27 VARCHAR(2),
  identifier_state_27 VARCHAR(2),
  identifier_issuer_27 VARCHAR(300),

  identifier_28 VARCHAR(100),
  identifier_type_28 VARCHAR(2),
  identifier_state_28 VARCHAR(2),
  identifier_issuer_28 VARCHAR(300),

  identifier_29 VARCHAR(100),
  identifier_type_29 VARCHAR(2),
  identifier_state_29 VARCHAR(2),
  identifier_issuer_29 VARCHAR(300),

  identifier_30 VARCHAR(100),
  identifier_type_30 VARCHAR(2),
  identifier_state_30 VARCHAR(2),
  identifier_issuer_30 VARCHAR(300),

  identifier_31 VARCHAR(100),
  identifier_type_31 VARCHAR(2),
  identifier_state_31 VARCHAR(2),
  identifier_issuer_31 VARCHAR(300),

  identifier_32 VARCHAR(100),
  identifier_type_32 VARCHAR(2),
  identifier_state_32 VARCHAR(2),
  identifier_issuer_32 VARCHAR(300),

  identifier_33 VARCHAR(100),
  identifier_type_33 VARCHAR(2),
  identifier_state_33 VARCHAR(2),
  identifier_issuer_33 VARCHAR(300),

  identifier_34 VARCHAR(100),
  identifier_type_34 VARCHAR(2),
  identifier_state_34 VARCHAR(2),
  identifier_issuer_34 VARCHAR(300),

  identifier_35 VARCHAR(100),
  identifier_type_35 VARCHAR(2),
  identifier_state_35 VARCHAR(2),
  identifier_issuer_35 VARCHAR(300),

  identifier_36 VARCHAR(100),
  identifier_type_36 VARCHAR(2),
  identifier_state_36 VARCHAR(2),
  identifier_issuer_36 VARCHAR(300),

  identifier_37 VARCHAR(100),
  identifier_type_37 VARCHAR(2),
  identifier_state_37 VARCHAR(2),
  identifier_issuer_37 VARCHAR(300),

  identifier_38 VARCHAR(100),
  identifier_type_38 VARCHAR(2),
  identifier_state_38 VARCHAR(2),
  identifier_issuer_38 VARCHAR(300),

  identifier_39 VARCHAR(100),
  identifier_type_39 VARCHAR(2),
  identifier_state_39 VARCHAR(2),
  identifier_issuer_39 VARCHAR(300),

  identifier_40 VARCHAR(100),
  identifier_type_40 VARCHAR(2),
  identifier_state_40 VARCHAR(2),
  identifier_issuer_40 VARCHAR(300),

  identifier_41 VARCHAR(100),
  identifier_type_41 VARCHAR(2),
  identifier_state_41 VARCHAR(2),
  identifier_issuer_41 VARCHAR(300),

  identifier_42 VARCHAR(100),
  identifier_type_42 VARCHAR(2),
  identifier_state_42 VARCHAR(2),
  identifier_issuer_42 VARCHAR(300),

  identifier_43 VARCHAR(100),
  identifier_type_43 VARCHAR(2),
  identifier_state_43 VARCHAR(2),
  identifier_issuer_43 VARCHAR(300),

  identifier_44 VARCHAR(100),
  identifier_type_44 VARCHAR(2),
  identifier_state_44 VARCHAR(2),
  identifier_issuer_44 VARCHAR(300),

  identifier_45 VARCHAR(100),
  identifier_type_45 VARCHAR(2),
  identifier_state_45 VARCHAR(2),
  identifier_issuer_45 VARCHAR(300),

  identifier_46 VARCHAR(100),
  identifier_type_46 VARCHAR(2),
  identifier_state_46 VARCHAR(2),
  identifier_issuer_46 VARCHAR(300),

  identifier_47 VARCHAR(100),
  identifier_type_47 VARCHAR(2),
  identifier_state_47 VARCHAR(2),
  identifier_issuer_47 VARCHAR(300),

  identifier_48 VARCHAR(100),
  identifier_type_48 VARCHAR(2),
  identifier_state_48 VARCHAR(2),
  identifier_issuer_48 VARCHAR(300),

  identifier_49 VARCHAR(100),
  identifier_type_49 VARCHAR(2),
  identifier_state_49 VARCHAR(2),
  identifier_issuer_49 VARCHAR(300),

  identifier_50 VARCHAR(100),
  identifier_type_50 VARCHAR(2),
  identifier_state_50 VARCHAR(2),
  identifier_issuer_50 VARCHAR(300)
);

-- Create index on NPI for faster lookups during transformation
CREATE INDEX IF NOT EXISTS idx_staging_npi ON staging_providers(npi);

-- Create index on entity type for filtered queries
CREATE INDEX IF NOT EXISTS idx_staging_entity_type ON staging_providers(entity_type_code);

-- Note: No need for additional indexes as this is a temporary staging table
-- Data will be transformed into normalized tables with proper indexes
