# PostgreSQL Database Schema for NPPES Healthcare Provider Directory

## Overview

This schema is designed to efficiently handle millions of healthcare provider records from the National Plan and Provider Enumeration System (NPPES), supporting:

- **Multiple provider types**: Doctors, Nurse Practitioners, Physician Assistants, Organizations, etc.
- **Complex searches**: By name, credentials, specialties, location, identifiers
- **Multiple relationships**: Taxonomies, addresses, identifiers per provider
- **Geographic filtering**: Normalized state/city data for efficient location-based searches
- **Full-text search**: Fast name-based queries using PostgreSQL's built-in capabilities

---

## Database Schema

### Entity Relationship Overview

```
providers (1) ──────< (many) provider_taxonomies (many) >────── (1) taxonomies
    │
    ├──────< (many) addresses >────── (1) cities ────── (1) states
    │
    ├──────< (many) identifiers
    │
    ├──────< (many) other_names
    │
    └──────< (many) endpoints
```

---

## Table Definitions

### 1. providers

Core table storing both individual providers (doctors, nurses, etc.) and organizational providers (hospitals, clinics).

```sql
CREATE TABLE providers (
  id BIGSERIAL PRIMARY KEY,

  -- NPI Information
  npi VARCHAR(10) NOT NULL UNIQUE,
  entity_type SMALLINT NOT NULL,              -- 1 = Individual, 2 = Organization
  replacement_npi VARCHAR(10),

  -- Individual Provider Fields (entity_type = 1)
  first_name VARCHAR(150),
  last_name VARCHAR(150),
  middle_name VARCHAR(150),
  name_prefix VARCHAR(10),                    -- Dr., Ms., etc.
  name_suffix VARCHAR(10),                    -- Jr., III, etc.
  credential VARCHAR(100),                    -- MD, DO, NP, PA, etc.
  gender CHAR(1),                             -- M, F, X

  -- Organization Provider Fields (entity_type = 2)
  organization_name VARCHAR(300),
  organization_subpart BOOLEAN DEFAULT false,

  -- Business Information
  ein VARCHAR(9),                             -- Employer ID Number
  sole_proprietor BOOLEAN DEFAULT false,

  -- Status & Dates
  enumeration_date DATE,
  last_update_date DATE,
  deactivation_date DATE,
  deactivation_reason VARCHAR(100),
  reactivation_date DATE,

  -- Full-text Search (computed column)
  search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', COALESCE(first_name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(last_name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(organization_name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(credential, '')), 'B')
  ) STORED,

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Constraints
  CONSTRAINT check_entity_type CHECK (entity_type IN (1, 2)),
  CONSTRAINT check_gender CHECK (gender IN ('M', 'F', 'X') OR gender IS NULL),
  CONSTRAINT check_individual_fields CHECK (
    (entity_type = 1 AND first_name IS NOT NULL AND last_name IS NOT NULL) OR
    (entity_type = 2 AND organization_name IS NOT NULL)
  )
);

-- Indexes
CREATE UNIQUE INDEX idx_providers_npi ON providers (npi);
CREATE INDEX idx_providers_entity_type ON providers (entity_type);
CREATE INDEX idx_providers_last_name ON providers (last_name) WHERE entity_type = 1;
CREATE INDEX idx_providers_organization_name ON providers (organization_name) WHERE entity_type = 2;
CREATE INDEX idx_providers_credential ON providers (credential) WHERE credential IS NOT NULL;

-- Full-text search index (GIN for fast text search)
CREATE INDEX idx_providers_search ON providers USING GIN (search_vector);

-- Partial index for active providers only
CREATE INDEX idx_providers_active ON providers (last_name, first_name)
WHERE deactivation_date IS NULL AND entity_type = 1;

-- Composite index for common queries
CREATE INDEX idx_providers_name_credential ON providers (last_name, first_name, credential)
WHERE entity_type = 1 AND deactivation_date IS NULL;

-- Comments
COMMENT ON TABLE providers IS 'Core table for healthcare providers (individuals and organizations)';
COMMENT ON COLUMN providers.npi IS 'National Provider Identifier - unique 10-digit number';
COMMENT ON COLUMN providers.entity_type IS '1 = Individual Provider, 2 = Organizational Provider';
COMMENT ON COLUMN providers.search_vector IS 'Full-text search vector (auto-generated)';
```

---

### 2. states

Normalized state/territory data for efficient geographic filtering.

```sql
CREATE TABLE states (
  id SERIAL PRIMARY KEY,
  code CHAR(2) NOT NULL UNIQUE,              -- CA, NY, TX, etc.
  name VARCHAR(100) NOT NULL,                -- California, New York, Texas
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX idx_states_code ON states (code);

-- Seed data
INSERT INTO states (code, name) VALUES
  ('AL', 'Alabama'), ('AK', 'Alaska'), ('AZ', 'Arizona'), ('AR', 'Arkansas'),
  ('CA', 'California'), ('CO', 'Colorado'), ('CT', 'Connecticut'), ('DE', 'Delaware'),
  ('FL', 'Florida'), ('GA', 'Georgia'), ('HI', 'Hawaii'), ('ID', 'Idaho'),
  ('IL', 'Illinois'), ('IN', 'Indiana'), ('IA', 'Iowa'), ('KS', 'Kansas'),
  ('KY', 'Kentucky'), ('LA', 'Louisiana'), ('ME', 'Maine'), ('MD', 'Maryland'),
  ('MA', 'Massachusetts'), ('MI', 'Michigan'), ('MN', 'Minnesota'), ('MS', 'Mississippi'),
  ('MO', 'Missouri'), ('MT', 'Montana'), ('NE', 'Nebraska'), ('NV', 'Nevada'),
  ('NH', 'New Hampshire'), ('NJ', 'New Jersey'), ('NM', 'New Mexico'), ('NY', 'New York'),
  ('NC', 'North Carolina'), ('ND', 'North Dakota'), ('OH', 'Ohio'), ('OK', 'Oklahoma'),
  ('OR', 'Oregon'), ('PA', 'Pennsylvania'), ('RI', 'Rhode Island'), ('SC', 'South Carolina'),
  ('SD', 'South Dakota'), ('TN', 'Tennessee'), ('TX', 'Texas'), ('UT', 'Utah'),
  ('VT', 'Vermont'), ('VA', 'Virginia'), ('WA', 'Washington'), ('WV', 'West Virginia'),
  ('WI', 'Wisconsin'), ('WY', 'Wyoming'), ('DC', 'District of Columbia'),
  ('PR', 'Puerto Rico'), ('VI', 'Virgin Islands'), ('GU', 'Guam'), ('AS', 'American Samoa');
```

---

### 3. cities

Normalized city data linked to states.

```sql
CREATE TABLE cities (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  state_id INTEGER NOT NULL REFERENCES states(id) ON DELETE RESTRICT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT unique_city_state UNIQUE (name, state_id)
);

-- Indexes
CREATE INDEX idx_cities_state_id ON cities (state_id);
CREATE INDEX idx_cities_name ON cities (name);
CREATE UNIQUE INDEX idx_cities_name_state ON cities (name, state_id);

COMMENT ON TABLE cities IS 'Normalized city data to reduce redundancy';
```

---

### 4. addresses

Practice locations and mailing addresses for providers.

```sql
CREATE TABLE addresses (
  id BIGSERIAL PRIMARY KEY,
  provider_id BIGINT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

  -- Address Type
  address_purpose VARCHAR(10) NOT NULL,      -- LOCATION or MAILING
  address_type VARCHAR(3) DEFAULT 'DOM',     -- DOM (domestic) or FGN (foreign)

  -- Address Fields
  address_1 VARCHAR(300),
  address_2 VARCHAR(300),
  city_id BIGINT REFERENCES cities(id) ON DELETE SET NULL,
  city_name VARCHAR(200),                    -- Denormalized for foreign addresses
  state_id INTEGER REFERENCES states(id) ON DELETE SET NULL,
  postal_code VARCHAR(20),
  country_code CHAR(2) DEFAULT 'US',

  -- Contact
  telephone VARCHAR(20),
  fax VARCHAR(20),

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT check_address_purpose CHECK (address_purpose IN ('LOCATION', 'MAILING')),
  CONSTRAINT check_address_type CHECK (address_type IN ('DOM', 'FGN'))
);

-- Indexes
CREATE INDEX idx_addresses_provider_id ON addresses (provider_id);
CREATE INDEX idx_addresses_city_id ON addresses (city_id);
CREATE INDEX idx_addresses_state_id ON addresses (state_id);
CREATE INDEX idx_addresses_purpose ON addresses (address_purpose);
CREATE INDEX idx_addresses_postal_code ON addresses (postal_code);

-- Composite index for location searches
CREATE INDEX idx_addresses_location_search ON addresses (state_id, city_id, address_purpose)
WHERE address_purpose = 'LOCATION';

-- Unique constraint: one primary location per provider
CREATE UNIQUE INDEX idx_addresses_primary_location ON addresses (provider_id, address_purpose)
WHERE address_purpose = 'LOCATION';

COMMENT ON TABLE addresses IS 'Provider practice locations and mailing addresses';
COMMENT ON COLUMN addresses.address_purpose IS 'LOCATION = practice address, MAILING = mailing address';
```

---

### 5. taxonomies

Normalized taxonomy codes (specialties, provider types).

```sql
CREATE TABLE taxonomies (
  id SERIAL PRIMARY KEY,
  code VARCHAR(10) NOT NULL UNIQUE,          -- e.g., 207Q00000X
  classification VARCHAR(200),               -- e.g., Allopathic & Osteopathic Physicians
  specialization VARCHAR(200),               -- e.g., Family Medicine
  description VARCHAR(500),                  -- Full description
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX idx_taxonomies_code ON taxonomies (code);
CREATE INDEX idx_taxonomies_classification ON taxonomies (classification);
CREATE INDEX idx_taxonomies_specialization ON taxonomies (specialization);

-- Common taxonomies seed data (examples)
INSERT INTO taxonomies (code, classification, specialization, description) VALUES
  ('207Q00000X', 'Allopathic & Osteopathic Physicians', 'Family Medicine', 'Family Medicine Physician'),
  ('208D00000X', 'Allopathic & Osteopathic Physicians', 'General Practice', 'General Practice Physician'),
  ('207R00000X', 'Allopathic & Osteopathic Physicians', 'Internal Medicine', 'Internal Medicine Physician'),
  ('207V00000X', 'Allopathic & Osteopathic Physicians', 'Obstetrics & Gynecology', 'Obstetrics & Gynecology'),
  ('208000000X', 'Allopathic & Osteopathic Physicians', 'Pediatrics', 'Pediatrics Physician'),
  ('363L00000X', 'Physician Assistants & Advanced Practice Nursing Providers', 'Nurse Practitioner', 'Nurse Practitioner'),
  ('363A00000X', 'Physician Assistants & Advanced Practice Nursing Providers', 'Physician Assistant', 'Physician Assistant'),
  ('122300000X', 'Dental Providers', 'Dentist', 'Dentist'),
  ('207N00000X', 'Allopathic & Osteopathic Physicians', 'Dermatology', 'Dermatology Physician'),
  ('207T00000X', 'Allopathic & Osteopathic Physicians', 'Neurological Surgery', 'Neurological Surgery');

COMMENT ON TABLE taxonomies IS 'Healthcare provider taxonomy/specialty codes';
```

---

### 6. provider_taxonomies

Join table linking providers to their taxonomies (many-to-many).

```sql
CREATE TABLE provider_taxonomies (
  id BIGSERIAL PRIMARY KEY,
  provider_id BIGINT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  taxonomy_id INTEGER NOT NULL REFERENCES taxonomies(id) ON DELETE RESTRICT,

  -- License Information
  license_number VARCHAR(100),
  license_state_id INTEGER REFERENCES states(id) ON DELETE SET NULL,

  -- Primary Taxonomy Flag
  is_primary BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT unique_provider_taxonomy UNIQUE (provider_id, taxonomy_id)
);

-- Indexes
CREATE INDEX idx_provider_taxonomies_provider_id ON provider_taxonomies (provider_id);
CREATE INDEX idx_provider_taxonomies_taxonomy_id ON provider_taxonomies (taxonomy_id);
CREATE INDEX idx_provider_taxonomies_primary ON provider_taxonomies (provider_id, is_primary)
WHERE is_primary = true;
CREATE INDEX idx_provider_taxonomies_license_state ON provider_taxonomies (license_state_id);

-- Unique constraint: only one primary taxonomy per provider
CREATE UNIQUE INDEX idx_provider_taxonomies_one_primary ON provider_taxonomies (provider_id)
WHERE is_primary = true;

COMMENT ON TABLE provider_taxonomies IS 'Links providers to their specialties/taxonomies (many-to-many)';
COMMENT ON COLUMN provider_taxonomies.is_primary IS 'Only one taxonomy can be marked as primary per provider';
```

---

### 7. identifiers

Other identifiers associated with providers (Medicare, Medicaid, DEA, etc.).

```sql
CREATE TABLE identifiers (
  id BIGSERIAL PRIMARY KEY,
  provider_id BIGINT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

  -- Identifier Information
  identifier_type VARCHAR(50) NOT NULL,      -- MEDICAID, MEDICARE, DEA, OTHER, etc.
  identifier_value VARCHAR(100) NOT NULL,
  state_id INTEGER REFERENCES states(id) ON DELETE SET NULL,
  issuer VARCHAR(200),                       -- Issuing organization

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT unique_provider_identifier UNIQUE (provider_id, identifier_type, identifier_value)
);

-- Indexes
CREATE INDEX idx_identifiers_provider_id ON identifiers (provider_id);
CREATE INDEX idx_identifiers_type ON identifiers (identifier_type);
CREATE INDEX idx_identifiers_value ON identifiers (identifier_value);
CREATE INDEX idx_identifiers_state_id ON identifiers (state_id);

-- Composite index for identifier searches
CREATE INDEX idx_identifiers_type_value ON identifiers (identifier_type, identifier_value);

COMMENT ON TABLE identifiers IS 'Other provider identifiers (Medicare, Medicaid, DEA, etc.)';
```

---

### 8. other_names

Former names and aliases for providers.

```sql
CREATE TABLE other_names (
  id BIGSERIAL PRIMARY KEY,
  provider_id BIGINT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

  -- Name Type
  name_type VARCHAR(50),                     -- Former Name, Alias, etc.

  -- Name Fields
  first_name VARCHAR(150),
  last_name VARCHAR(150),
  middle_name VARCHAR(150),
  name_prefix VARCHAR(10),
  name_suffix VARCHAR(10),
  credential VARCHAR(100),
  organization_name VARCHAR(300),

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_other_names_provider_id ON other_names (provider_id);
CREATE INDEX idx_other_names_last_name ON other_names (last_name);
CREATE INDEX idx_other_names_organization ON other_names (organization_name);

COMMENT ON TABLE other_names IS 'Former names and aliases for providers';
```

---

### 9. endpoints

Electronic health record endpoints (FHIR, Direct, etc.).

```sql
CREATE TABLE endpoints (
  id BIGSERIAL PRIMARY KEY,
  provider_id BIGINT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

  -- Endpoint Information
  endpoint_url VARCHAR(500) NOT NULL,
  endpoint_type VARCHAR(50),                 -- FHIR, DIRECT, etc.
  endpoint_description TEXT,

  -- Metadata
  content_type VARCHAR(100),                 -- MIME type
  use_type VARCHAR(50),                      -- Usage type
  affiliation BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_endpoints_provider_id ON endpoints (provider_id);
CREATE INDEX idx_endpoints_type ON endpoints (endpoint_type);

COMMENT ON TABLE endpoints IS 'Electronic health record endpoints for providers';
```

---

### 10. authorized_officials

Authorized officials for organizational providers.

```sql
CREATE TABLE authorized_officials (
  id BIGSERIAL PRIMARY KEY,
  provider_id BIGINT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

  -- Official Information
  first_name VARCHAR(150) NOT NULL,
  last_name VARCHAR(150) NOT NULL,
  middle_name VARCHAR(150),
  name_prefix VARCHAR(10),
  name_suffix VARCHAR(10),
  credential VARCHAR(100),

  -- Contact & Position
  title_or_position VARCHAR(200),
  telephone VARCHAR(20),

  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT unique_provider_official UNIQUE (provider_id)
);

-- Indexes
CREATE UNIQUE INDEX idx_authorized_officials_provider ON authorized_officials (provider_id);

COMMENT ON TABLE authorized_officials IS 'Authorized officials for organizational providers';
```

---

## Indexing Strategy

### Primary Indexes (Already Defined Above)

1. **Full-Text Search** (GIN index on `providers.search_vector`)
   - Fastest text search for names
   - Weighted: names (A) > credentials (B)

2. **Geographic Filtering** (Composite indexes)
   - `addresses(state_id, city_id, address_purpose)` for location-based searches
   - `cities(name, state_id)` for city lookups

3. **Taxonomy Searches** (Multiple indexes)
   - `provider_taxonomies(taxonomy_id)` for specialty filtering
   - `taxonomies(classification, specialization)` for taxonomy lookups

4. **Partial Indexes** (Active providers only)
   - Reduces index size and improves query performance
   - `WHERE deactivation_date IS NULL`

5. **Unique Constraints as Indexes**
   - `providers.npi` (unique identifier)
   - `provider_taxonomies` one primary per provider
   - One primary location per provider

### Performance Considerations

```sql
-- Enable autovacuum (should be on by default)
ALTER TABLE providers SET (autovacuum_enabled = true);
ALTER TABLE addresses SET (autovacuum_enabled = true);
ALTER TABLE provider_taxonomies SET (autovacuum_enabled = true);

-- Increase statistics target for frequently queried columns
ALTER TABLE providers ALTER COLUMN last_name SET STATISTICS 1000;
ALTER TABLE providers ALTER COLUMN first_name SET STATISTICS 1000;
ALTER TABLE addresses ALTER COLUMN state_id SET STATISTICS 1000;
```

---

## Rails Model Associations

### app/models/provider.rb

```ruby
class Provider < ApplicationRecord
  # Enums
  enum entity_type: { individual: 1, organization: 2 }
  enum gender: { male: 'M', female: 'F', other: 'X' }, _prefix: true

  # Associations
  has_many :addresses, dependent: :destroy
  has_many :provider_taxonomies, dependent: :destroy
  has_many :taxonomies, through: :provider_taxonomies
  has_many :identifiers, dependent: :destroy
  has_many :other_names, dependent: :destroy
  has_many :endpoints, dependent: :destroy
  has_one :authorized_official, dependent: :destroy

  # Delegations
  has_many :cities, through: :addresses
  has_many :states, through: :addresses

  # Validations
  validates :npi, presence: true, uniqueness: true, length: { is: 10 }
  validates :entity_type, presence: true, inclusion: { in: [1, 2] }
  validates :first_name, :last_name, presence: true, if: :individual?
  validates :organization_name, presence: true, if: :organization?
  validates :gender, inclusion: { in: %w[M F X] }, allow_nil: true

  # Scopes
  scope :active, -> { where(deactivation_date: nil) }
  scope :deactivated, -> { where.not(deactivation_date: nil) }
  scope :individuals, -> { where(entity_type: 1) }
  scope :organizations, -> { where(entity_type: 2) }
  scope :with_credential, ->(credential) { where(credential: credential) }

  # Search scopes
  scope :search_by_name, ->(query) {
    where("search_vector @@ plainto_tsquery('english', ?)", query)
  }

  scope :in_state, ->(state_code) {
    joins(addresses: :state)
      .where(addresses: { address_purpose: 'LOCATION' })
      .where(states: { code: state_code })
  }

  scope :in_city, ->(city_name, state_code) {
    joins(addresses: [:city, :state])
      .where(addresses: { address_purpose: 'LOCATION' })
      .where(cities: { name: city_name })
      .where(states: { code: state_code })
  }

  scope :with_taxonomy, ->(taxonomy_code) {
    joins(:taxonomies).where(taxonomies: { code: taxonomy_code })
  }

  # Instance methods
  def full_name
    if individual?
      [name_prefix, first_name, middle_name, last_name, name_suffix, credential]
        .compact.join(' ')
    else
      organization_name
    end
  end

  def primary_taxonomy
    provider_taxonomies.find_by(is_primary: true)&.taxonomy
  end

  def primary_location
    addresses.find_by(address_purpose: 'LOCATION')
  end

  def mailing_address
    addresses.find_by(address_purpose: 'MAILING')
  end

  def active?
    deactivation_date.nil?
  end
end
```

---

### app/models/taxonomy.rb

```ruby
class Taxonomy < ApplicationRecord
  # Associations
  has_many :provider_taxonomies, dependent: :restrict_with_error
  has_many :providers, through: :provider_taxonomies

  # Validations
  validates :code, presence: true, uniqueness: true, length: { is: 10 }

  # Scopes
  scope :physicians, -> { where("classification ILIKE '%physician%'") }
  scope :nurses, -> { where("classification ILIKE '%nurs%'") }
  scope :by_classification, ->(classification) {
    where("classification ILIKE ?", "%#{classification}%")
  }

  # Instance methods
  def display_name
    [classification, specialization].compact.join(' - ')
  end
end
```

---

### app/models/provider_taxonomy.rb

```ruby
class ProviderTaxonomy < ApplicationRecord
  # Associations
  belongs_to :provider
  belongs_to :taxonomy
  belongs_to :license_state, class_name: 'State', optional: true

  # Validations
  validates :provider_id, uniqueness: { scope: :taxonomy_id }
  validate :only_one_primary_per_provider, if: :is_primary?

  # Scopes
  scope :primary, -> { where(is_primary: true) }
  scope :secondary, -> { where(is_primary: false) }

  private

  def only_one_primary_per_provider
    if provider.provider_taxonomies.where(is_primary: true).where.not(id: id).exists?
      errors.add(:is_primary, 'provider can only have one primary taxonomy')
    end
  end
end
```

---

### app/models/address.rb

```ruby
class Address < ApplicationRecord
  # Associations
  belongs_to :provider
  belongs_to :city, optional: true
  belongs_to :state, optional: true

  # Validations
  validates :address_purpose, presence: true, inclusion: { in: %w[LOCATION MAILING] }
  validates :address_type, inclusion: { in: %w[DOM FGN] }

  # Scopes
  scope :locations, -> { where(address_purpose: 'LOCATION') }
  scope :mailing, -> { where(address_purpose: 'MAILING') }
  scope :domestic, -> { where(address_type: 'DOM') }
  scope :foreign, -> { where(address_type: 'FGN') }
  scope :in_state, ->(state_code) {
    joins(:state).where(states: { code: state_code })
  }

  # Instance methods
  def full_address
    [address_1, address_2, city_name, state&.code, postal_code]
      .compact.join(', ')
  end

  def location?
    address_purpose == 'LOCATION'
  end

  def mailing?
    address_purpose == 'MAILING'
  end
end
```

---

### app/models/state.rb

```ruby
class State < ApplicationRecord
  # Associations
  has_many :cities, dependent: :restrict_with_error
  has_many :addresses, dependent: :restrict_with_error
  has_many :providers, through: :addresses

  # Validations
  validates :code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true

  # Scopes
  scope :with_providers, -> {
    joins(:providers).distinct
  }

  def to_s
    code
  end
end
```

---

### app/models/city.rb

```ruby
class City < ApplicationRecord
  # Associations
  belongs_to :state
  has_many :addresses, dependent: :restrict_with_error
  has_many :providers, through: :addresses

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :state_id }

  # Scopes
  scope :in_state, ->(state_code) {
    joins(:state).where(states: { code: state_code })
  }

  def full_name
    "#{name}, #{state.code}"
  end
end
```

---

### app/models/identifier.rb

```ruby
class Identifier < ApplicationRecord
  # Associations
  belongs_to :provider
  belongs_to :state, optional: true

  # Validations
  validates :identifier_type, presence: true
  validates :identifier_value, presence: true
  validates :identifier_value, uniqueness: {
    scope: [:provider_id, :identifier_type]
  }

  # Scopes
  scope :medicaid, -> { where(identifier_type: 'MEDICAID') }
  scope :medicare, -> { where(identifier_type: 'MEDICARE') }
  scope :dea, -> { where(identifier_type: 'DEA') }
  scope :by_type, ->(type) { where(identifier_type: type) }
end
```

---

### app/models/other_name.rb

```ruby
class OtherName < ApplicationRecord
  belongs_to :provider

  validates :name_type, presence: true

  def full_name
    if first_name.present?
      [name_prefix, first_name, middle_name, last_name, name_suffix, credential]
        .compact.join(' ')
    else
      organization_name
    end
  end
end
```

---

### app/models/endpoint.rb

```ruby
class Endpoint < ApplicationRecord
  belongs_to :provider

  validates :endpoint_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  scope :fhir, -> { where(endpoint_type: 'FHIR') }
  scope :direct, -> { where(endpoint_type: 'DIRECT') }
end
```

---

### app/models/authorized_official.rb

```ruby
class AuthorizedOfficial < ApplicationRecord
  belongs_to :provider

  validates :first_name, :last_name, presence: true
  validates :provider_id, uniqueness: true

  def full_name
    [name_prefix, first_name, middle_name, last_name, name_suffix, credential]
      .compact.join(' ')
  end
end
```

---

## Example Queries

### 1. Search by Name (Full-Text Search)

```ruby
# Find providers by name using full-text search
Provider.search_by_name("john smith")

# SQL generated:
# SELECT * FROM providers
# WHERE search_vector @@ plainto_tsquery('english', 'john smith')
```

### 2. Search by Location

```ruby
# Find all doctors in California
Provider.active.individuals.in_state('CA')

# Find all doctors in Boston, MA
Provider.active.in_city('Boston', 'MA')

# SQL for state search:
# SELECT providers.* FROM providers
# INNER JOIN addresses ON addresses.provider_id = providers.id
# INNER JOIN states ON states.id = addresses.state_id
# WHERE addresses.address_purpose = 'LOCATION'
#   AND states.code = 'CA'
#   AND providers.deactivation_date IS NULL
#   AND providers.entity_type = 1
```

### 3. Search by Specialty/Taxonomy

```ruby
# Find all family medicine physicians
Provider.active.with_taxonomy('207Q00000X')

# Find all nurse practitioners
taxonomy = Taxonomy.find_by(code: '363L00000X')
taxonomy.providers.active

# Complex: Family medicine doctors in California
Provider.active
  .individuals
  .with_taxonomy('207Q00000X')
  .in_state('CA')
```

### 4. Search by Credential

```ruby
# Find all MDs
Provider.active.individuals.with_credential('MD')

# Find all Nurse Practitioners
Provider.active.where(credential: 'NP')
```

### 5. Complex Multi-Criteria Search

```ruby
# Find MDs specializing in Family Medicine in Boston, MA
Provider.active
  .individuals
  .with_credential('MD')
  .with_taxonomy('207Q00000X')
  .in_city('Boston', 'MA')

# Find providers with multiple practice locations
Provider.joins(:addresses)
  .where(addresses: { address_purpose: 'LOCATION' })
  .group('providers.id')
  .having('COUNT(addresses.id) > 1')
```

### 6. Geographic Aggregations

```ruby
# Count providers by state
Provider.active
  .joins(addresses: :state)
  .where(addresses: { address_purpose: 'LOCATION' })
  .group('states.name')
  .count

# Providers per city in California
Provider.active
  .joins(addresses: [:city, :state])
  .where(addresses: { address_purpose: 'LOCATION' })
  .where(states: { code: 'CA' })
  .group('cities.name')
  .count
```

### 7. Taxonomy Analysis

```ruby
# Most common specialties
Taxonomy.joins(:provider_taxonomies)
  .where(provider_taxonomies: { is_primary: true })
  .group('taxonomies.specialization')
  .order('COUNT(provider_taxonomies.id) DESC')
  .limit(10)
  .count

# Providers with multiple specialties
Provider.joins(:provider_taxonomies)
  .group('providers.id')
  .having('COUNT(provider_taxonomies.id) > 1')
```

### 8. Raw SQL for Performance-Critical Queries

```ruby
# Complex search with full-text and filters
sql = <<-SQL
  SELECT DISTINCT p.*
  FROM providers p
  INNER JOIN addresses a ON a.provider_id = p.id
  INNER JOIN states s ON s.id = a.state_id
  INNER JOIN provider_taxonomies pt ON pt.provider_id = p.id
  WHERE p.search_vector @@ plainto_tsquery('english', ?)
    AND s.code = ?
    AND pt.taxonomy_id = ?
    AND p.deactivation_date IS NULL
    AND a.address_purpose = 'LOCATION'
  ORDER BY ts_rank(p.search_vector, plainto_tsquery('english', ?)) DESC
  LIMIT 50
SQL

Provider.find_by_sql([sql, 'smith', 'CA', taxonomy_id, 'smith'])
```

### 9. Autocomplete Query

```ruby
# Fast autocomplete for provider names
def autocomplete_providers(query, limit = 10)
  Provider.select(:id, :first_name, :last_name, :organization_name, :credential)
    .where("search_vector @@ plainto_tsquery('english', ?)", query)
    .order(
      Arel.sql("ts_rank(search_vector, plainto_tsquery('english', '#{query}')) DESC")
    )
    .limit(limit)
end
```

### 10. Dashboard Statistics

```ruby
# Provider statistics
stats = {
  total: Provider.active.count,
  individuals: Provider.active.individuals.count,
  organizations: Provider.active.organizations.count,
  states: State.joins(:providers).distinct.count,
  specialties: Taxonomy.joins(:providers).distinct.count
}

# Breakdown by credential
Provider.active.individuals
  .group(:credential)
  .order('COUNT(*) DESC')
  .count
```

---

## Performance Tips

### 1. Use EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT * FROM providers
WHERE search_vector @@ plainto_tsquery('english', 'smith')
  AND deactivation_date IS NULL
LIMIT 20;
```

### 2. Optimize Join Queries

```ruby
# Eager load associations to avoid N+1 queries
Provider.includes(:addresses, :taxonomies, :identifiers)
  .where(deactivation_date: nil)
  .limit(20)
```

### 3. Use Counter Caches

```ruby
# Add counter cache for frequently counted associations
add_column :providers, :addresses_count, :integer, default: 0
add_column :providers, :taxonomies_count, :integer, default: 0

# In models:
belongs_to :provider, counter_cache: true
```

### 4. Database Connection Pooling

```yaml
# config/database.yml
production:
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
```

### 5. Use Database Views for Complex Queries

```sql
CREATE VIEW provider_directory AS
SELECT
  p.id,
  p.npi,
  p.first_name,
  p.last_name,
  p.credential,
  p.organization_name,
  t.specialization AS primary_specialty,
  a.city_name,
  s.code AS state_code,
  a.postal_code
FROM providers p
LEFT JOIN provider_taxonomies pt ON pt.provider_id = p.id AND pt.is_primary = true
LEFT JOIN taxonomies t ON t.id = pt.taxonomy_id
LEFT JOIN addresses a ON a.provider_id = p.id AND a.address_purpose = 'LOCATION'
LEFT JOIN states s ON s.id = a.state_id
WHERE p.deactivation_date IS NULL;

-- Use in Rails:
# app/models/provider_directory.rb
class ProviderDirectory < ApplicationRecord
  self.primary_key = 'id'

  def readonly?
    true
  end
end
```

---

## Summary

This schema provides:

✅ **Normalized structure** - Reduces redundancy, maintains data integrity
✅ **Efficient searches** - Full-text search, composite indexes, partial indexes
✅ **Flexible relationships** - Many-to-many for taxonomies, one-to-many for addresses
✅ **Geographic filtering** - Normalized states/cities for fast location queries
✅ **Multiple provider types** - Handles individuals and organizations
✅ **Scalable** - Designed for millions of records
✅ **PostgreSQL-optimized** - Uses GIN indexes, tsvector, and advanced features
✅ **Rails-friendly** - Clear associations, validations, and scopes

The schema supports all NPPES data requirements while maintaining query performance for name, location, specialty, and credential searches.
