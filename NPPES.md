# NPPES (National Plan and Provider Enumeration System) Data Reference

## Overview

The National Plan and Provider Enumeration System (NPPES) is the official U.S. registry of healthcare providers maintained by the Centers for Medicare and Medicaid Services (CMS). Every healthcare provider receives a unique 10-digit National Provider Identifier (NPI).

**Data Sources Available:**
1. **CMS NPI Registry API** - Real-time REST API with comprehensive data
2. **NLM Clinical Tables API** - Simplified API for autocomplete/search
3. **NPPES Downloadable File** - Full CSV dataset (6+ GB, ~330 columns)

---

## 1. CMS NPI Registry API

### Endpoint
```
https://npiregistry.cms.hhs.gov/api/
```

### Authentication
No API key required - completely free and public

### Version
Current version: 2.1

### Request Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `version` | string | API version (required) | `2.1` |
| `number` | string | NPI number | `1234567890` |
| `enumeration_type` | string | `NPI-1` (individual) or `NPI-2` (org) | `NPI-1` |
| `taxonomy_description` | string | Provider specialty | `Family Medicine` |
| `first_name` | string | Provider first name | `John` |
| `last_name` | string | Provider last name | `Smith` |
| `organization_name` | string | Organization name | `Acme Medical` |
| `address_purpose` | string | `LOCATION` or `MAILING` | `LOCATION` |
| `city` | string | City name | `Boston` |
| `state` | string | Two-letter state code | `MA` |
| `postal_code` | string | ZIP code | `02101` |
| `country_code` | string | Country code | `US` |
| `limit` | integer | Max results (max 200) | `10` |
| `skip` | integer | Pagination offset | `0` |

### Example Request

**Search by Name and State:**
```bash
curl "https://npiregistry.cms.hhs.gov/api/?version=2.1&first_name=John&last_name=Smith&state=CA&limit=10"
```

**Search by NPI:**
```bash
curl "https://npiregistry.cms.hhs.gov/api/?version=2.1&number=1234567890"
```

**Search by Organization:**
```bash
curl "https://npiregistry.cms.hhs.gov/api/?version=2.1&organization_name=Kaiser&city=Los%20Angeles&limit=5"
```

### JSON Response Structure

```json
{
  "result_count": 150,
  "results": [
    {
      "number": "1234567890",
      "enumeration_type": "NPI-1",
      "created_epoch": 1234567890,
      "last_updated_epoch": 1234567890,

      "basic": {
        // === For Individuals (NPI-1) ===
        "first_name": "John",
        "last_name": "Smith",
        "middle_name": "Robert",
        "credential": "MD",
        "gender": "M",
        "sole_proprietor": "YES",
        "name_prefix": "Dr.",
        "name_suffix": "Jr.",

        // === For Organizations (NPI-2) ===
        "organization_name": "Acme Medical Center",
        "organizational_subpart": "NO",
        "authorized_official_first_name": "Jane",
        "authorized_official_last_name": "Doe",
        "authorized_official_middle_name": "Marie",
        "authorized_official_title_or_position": "CEO",
        "authorized_official_telephone_number": "310-555-1234",
        "authorized_official_credential": "MBA"
      },

      "addresses": [
        {
          "country_code": "US",
          "country_name": "United States",
          "address_purpose": "LOCATION",
          "address_type": "DOM",
          "address_1": "123 Main Street",
          "address_2": "Suite 100",
          "city": "Los Angeles",
          "state": "CA",
          "postal_code": "90210-1234",
          "telephone_number": "310-555-1234",
          "fax_number": "310-555-1235"
        },
        {
          "country_code": "US",
          "country_name": "United States",
          "address_purpose": "MAILING",
          "address_type": "DOM",
          "address_1": "PO Box 5678",
          "city": "Los Angeles",
          "state": "CA",
          "postal_code": "90210"
        }
      ],

      "taxonomies": [
        {
          "code": "207Q00000X",
          "taxonomy_group": "Allopathic & Osteopathic Physicians",
          "desc": "Family Medicine",
          "state": "CA",
          "license": "A12345",
          "primary": true
        },
        {
          "code": "208D00000X",
          "taxonomy_group": "Allopathic & Osteopathic Physicians",
          "desc": "General Practice",
          "state": "CA",
          "license": "A12345",
          "primary": false
        }
      ],

      "identifiers": [
        {
          "code": "05",
          "desc": "MEDICAID",
          "identifier": "MED123456",
          "state": "CA",
          "issuer": "CA DHCS"
        },
        {
          "code": "01",
          "desc": "OTHER",
          "identifier": "DEA123456",
          "state": "CA",
          "issuer": "DEA"
        }
      ],

      "endpoints": [
        {
          "endpoint": "https://provider.example.com/fhir",
          "endpoint_type": "FHIR",
          "endpoint_type_description": "FHIR",
          "endpoint_description": "FHIR Endpoint for EHR Data",
          "affiliation": "Y",
          "use": "Direct",
          "content_type": "application/fhir+json",
          "country_code": "US"
        }
      ],

      "other_names": [
        {
          "type": "Former Name",
          "code": "1",
          "first_name": "John",
          "last_name": "Jones",
          "middle_name": "R",
          "prefix": "Dr.",
          "suffix": "",
          "credential": "MD"
        }
      ],

      "practice_locations": [
        {
          "country_code": "US",
          "country_name": "United States",
          "address_purpose": "LOCATION",
          "address_type": "DOM",
          "address_1": "456 Secondary St",
          "city": "San Francisco",
          "state": "CA",
          "postal_code": "94102",
          "telephone_number": "415-555-9999"
        }
      ]
    }
  ]
}
```

### Response Fields Reference

#### Top-Level Fields
- `result_count` - Total number of matching providers
- `results` - Array of provider records

#### Provider Record Fields
- `number` - 10-digit NPI
- `enumeration_type` - `NPI-1` (Individual) or `NPI-2` (Organization)
- `created_epoch` - Unix timestamp of NPI creation
- `last_updated_epoch` - Unix timestamp of last update

#### Basic Object Fields

**Individual Providers (NPI-1):**
- `first_name`, `last_name`, `middle_name`
- `name_prefix` - e.g., "Dr.", "Ms."
- `name_suffix` - e.g., "Jr.", "III"
- `credential` - e.g., "MD", "DO", "NP", "PA"
- `gender` - "M", "F", or "X"
- `sole_proprietor` - "YES" or "NO"

**Organizations (NPI-2):**
- `organization_name` - Legal business name
- `organizational_subpart` - "YES" or "NO"
- `authorized_official_first_name`, `authorized_official_last_name`
- `authorized_official_middle_name`
- `authorized_official_title_or_position`
- `authorized_official_telephone_number`
- `authorized_official_credential`

#### Addresses Array
- `country_code`, `country_name`
- `address_purpose` - "LOCATION" or "MAILING"
- `address_type` - "DOM" (domestic) or "FGN" (foreign)
- `address_1`, `address_2` - Street address lines
- `city`, `state`, `postal_code`
- `telephone_number`, `fax_number`

#### Taxonomies Array
- `code` - Healthcare Provider Taxonomy Code
- `taxonomy_group` - High-level category
- `desc` - Description of specialty
- `state` - State where license is valid
- `license` - License number
- `primary` - Boolean indicating primary taxonomy

#### Identifiers Array
- `code` - Identifier type code
- `desc` - Description (e.g., "MEDICAID", "MEDICARE")
- `identifier` - The actual ID number
- `state` - State code
- `issuer` - Issuing organization

#### Endpoints Array (for electronic health records)
- `endpoint` - URL of endpoint
- `endpoint_type` - Type (e.g., "FHIR", "DIRECT")
- `endpoint_type_description`
- `endpoint_description`
- `affiliation` - "Y" or "N"
- `use` - Usage type
- `content_type` - MIME type
- `country_code`

#### Other Names Array (former names, aliases)
- `type` - Name type
- `code` - Type code
- `first_name`, `last_name`, `middle_name`
- `prefix`, `suffix`, `credential`

---

## 2. NLM Clinical Tables API

### Endpoint
```
https://clinicaltables.nlm.nih.gov/api/npi_idv/v3/search
```

### Purpose
Simplified API designed for autocomplete and quick searches. Returns less data but faster response times.

### Authentication
No API key required

### Request Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `terms` | string | Search terms (required) | - |
| `maxList` | integer | Max results | 7 (max: 500) |
| `count` | integer | Results per page | 7 |
| `offset` | integer | Starting result number | 0 |

### Example Request

```bash
curl "https://clinicaltables.nlm.nih.gov/api/npi_idv/v3/search?terms=smith+boston&maxList=10"
```

### Response Structure

The API returns a JSON array with 5 elements:

```json
[
  127,                                    // [0] Total count
  ["1760880173", "1033132295"],          // [1] Array of NPIs
  null,                                   // [2] Extra data (if requested via 'ef' parameter)
  [                                       // [3] Display strings for each result
    "1760880173 - JOHN SMITH, MD - Family Medicine - 123 MAIN ST, BOSTON, MA 02101, US",
    "1033132295 - JANE SMITH, NP - Nurse Practitioner - 456 ELM ST, BOSTON, MA 02102, US"
  ],
  []                                      // [4] Code system array
]
```

### Response Array Elements

0. **Total Count** - Integer representing total matching results
1. **NPI Codes** - Array of NPI numbers as strings
2. **Extra Data** - Hash of additional data (null by default, use `ef` parameter to request specific fields)
3. **Display Strings** - Array of formatted strings for display
4. **Code System** - Array for code systems (rarely used)

### For Organizations

```
https://clinicaltables.nlm.nih.gov/api/npi_org/v3/search
```

Same structure, but returns organizational NPIs.

---

## 3. NPPES Downloadable File (CSV)

### Access
```
https://download.cms.gov/nppes/NPI_Files.html
```

### File Details
- **Format**: CSV (comma-separated values)
- **Size**: 6+ GB uncompressed
- **Columns**: Approximately 330 fields
- **Update Frequency**:
  - Full file: Monthly
  - Incremental updates: Weekly
  - Deactivation files: Monthly

### Important Notes
- Cannot be opened in Microsoft Excel (file too large)
- Use database import tools, pandas, or specialized CSV processors
- Contains all NPIs (individual and organizational)
- Only includes FOIA-disclosable information

### File Structure

Each row represents one healthcare provider. The file is flat (not normalized), so fields repeat for multiple values (e.g., up to 15 taxonomies per provider, up to 50 other identifiers).

### CSV Column Reference (~330 columns)

#### Core Identification (15 columns)
```
NPI
Entity Type Code                                    // 1 = Individual, 2 = Organization
Replacement NPI
Employer Identification Number (EIN)
Provider Organization Name (Legal Business Name)
Provider Last Name (Legal Name)
Provider First Name
Provider Middle Name
Provider Name Prefix Text
Provider Name Suffix Text
Provider Credential Text
Provider Other Organization Name
Provider Other Organization Name Type Code
Provider Other Last Name
Provider Other First Name
```

#### Other Names/Former Names (9 columns)
```
Provider Other Middle Name
Provider Other Name Prefix Text
Provider Other Name Suffix Text
Provider Other Credential Text
Provider Other Last Name Type Code
Provider First Line Business Mailing Address
Provider Second Line Business Mailing Address
```

#### Business Mailing Address (8 columns)
```
Provider Business Mailing Address City Name
Provider Business Mailing Address State Name
Provider Business Mailing Address Postal Code
Provider Business Mailing Address Country Code (If outside U.S.)
Provider Business Mailing Address Telephone Number
Provider Business Mailing Address Fax Number
```

#### Business Practice Location Address (8 columns)
```
Provider First Line Business Practice Location Address
Provider Second Line Business Practice Location Address
Provider Business Practice Location Address City Name
Provider Business Practice Location Address State Name
Provider Business Practice Location Address Postal Code
Provider Business Practice Location Address Country Code (If outside U.S.)
Provider Business Practice Location Address Telephone Number
Provider Business Practice Location Address Fax Number
```

#### Enumeration Information (6 columns)
```
Provider Enumeration Date
Last Update Date
NPI Deactivation Reason Code
NPI Deactivation Date
NPI Reactivation Date
Provider Gender Code                                // M, F, or blank
```

#### Authorized Official (for Organizations) (9 columns)
```
Authorized Official Last Name
Authorized Official First Name
Authorized Official Middle Name
Authorized Official Title or Position
Authorized Official Telephone Number
Authorized Official Name Prefix Text
Authorized Official Name Suffix Text
Authorized Official Credential Text
```

#### Certification/Business Details (4 columns)
```
Is Sole Proprietor                                  // Y or N
Is Organization Subpart                             // Y or N
Parent Organization LBN
Parent Organization TIN
```

#### Healthcare Provider Taxonomy (15 sets × 4 fields = 60 columns)

For each taxonomy slot (1-15):
```
Healthcare Provider Taxonomy Code_1                 // e.g., 207Q00000X
Healthcare Provider Taxonomy Group_1                // e.g., Allopathic & Osteopathic Physicians
Provider License Number_1
Provider License Number State Code_1
Healthcare Provider Primary Taxonomy Switch_1       // Y or N (only one should be Y)

// ... repeats for _2 through _15
```

#### Other Provider Identifiers (50 sets × 4 fields = 200 columns)

For each identifier slot (1-50):
```
Other Provider Identifier_1
Other Provider Identifier Type Code_1
Other Provider Identifier State_1
Other Provider Identifier Issuer_1

// ... repeats for _2 through _50
```

### Example CSV Row (simplified, actual has 330+ columns)

```csv
NPI,Entity Type Code,Provider Last Name,Provider First Name,Provider Middle Name,Provider Credential Text,Provider Gender Code,Provider First Line Business Practice Location Address,Provider Business Practice Location Address City Name,Provider Business Practice Location Address State Name,Provider Business Practice Location Address Postal Code,Healthcare Provider Taxonomy Code_1,Healthcare Provider Taxonomy Group_1,Healthcare Provider Primary Taxonomy Switch_1,Provider License Number_1,Provider License Number State Code_1
1234567890,1,Smith,John,Robert,MD,M,"123 Main Street",Boston,MA,02101-1234,207Q00000X,"Allopathic & Osteopathic Physicians",Y,A12345,MA
```

### Common Taxonomy Codes

| Code | Description |
|------|-------------|
| 207Q00000X | Family Medicine |
| 208D00000X | General Practice |
| 207R00000X | Internal Medicine |
| 207V00000X | Obstetrics & Gynecology |
| 208000000X | Pediatrics |
| 207T00000X | Neurological Surgery |
| 207N00000X | Dermatology |
| 363L00000X | Nurse Practitioner |
| 363A00000X | Physician Assistant |
| 122300000X | Dentist |

### Common Identifier Type Codes

| Code | Description |
|------|-------------|
| 01 | Other |
| 02 | Medicare UPIN |
| 04 | Medicare ID-TYPE UNSPECIFIED |
| 05 | Medicaid |
| 06 | Medicare OSCAR/Certification |
| 07 | Medicare NSC |
| 08 | Medicare PIN |

---

## Comparison Table

| Feature | CMS API | NLM API | CSV File |
|---------|---------|---------|----------|
| **Format** | JSON | JSON Array | CSV |
| **File Size** | On-demand | On-demand | 6+ GB |
| **Number of Fields** | ~40 nested | ~10 simplified | ~330 flat |
| **Authentication** | None | None | None |
| **Update Frequency** | Real-time | Daily | Weekly/Monthly |
| **Max Results** | 200 per request | 500 per request | All (~9M providers) |
| **Pagination** | Yes (`skip`, `limit`) | Yes (`offset`, `count`) | N/A |
| **Best Use Case** | Live search UI | Autocomplete | Bulk analysis/import |
| **Response Time** | ~1-3 seconds | <1 second | N/A (download) |
| **Complexity** | Medium | Low | High |
| **Nested Data** | Yes | No | No |
| **Specialty Info** | Full taxonomies | Basic | Full (15 slots) |
| **Address Data** | Multiple, detailed | Single string | Detailed |
| **Practice Locations** | Yes | Limited | Limited |
| **Former Names** | Yes | No | Yes |
| **Endpoints (FHIR)** | Yes | No | No |

---

## Use Cases & Recommendations

### 1. Doctor Search Feature
**Recommended:** CMS API
- Real-time data
- Comprehensive search filters
- Rich provider details

**Example Implementation:**
```ruby
# In your Rails controller
def search_npi
  require 'net/http'
  require 'json'

  params = {
    version: '2.1',
    first_name: params[:first_name],
    last_name: params[:last_name],
    state: params[:state],
    limit: 20
  }

  uri = URI('https://npiregistry.cms.hhs.gov/api/')
  uri.query = URI.encode_www_form(params.compact)

  response = Net::HTTP.get_response(uri)
  data = JSON.parse(response.body)

  @providers = data['results']
end
```

### 2. Autocomplete/Type-ahead
**Recommended:** NLM Clinical Tables API
- Fast response times
- Simple integration
- Designed for this use case

**Example:**
```javascript
// Stimulus controller for autocomplete
fetch(`https://clinicaltables.nlm.nih.gov/api/npi_idv/v3/search?terms=${searchTerm}&maxList=10`)
  .then(res => res.json())
  .then(data => {
    const [count, npis, extra, displayStrings] = data;
    // Show displayStrings in dropdown
  });
```

### 3. Bulk Import / Data Warehouse
**Recommended:** NPPES CSV File
- Complete dataset
- Weekly updates
- Best for analytics

**Example:**
```ruby
# Import to database
require 'csv'

CSV.foreach('npidata.csv', headers: true) do |row|
  next if row['Entity Type Code'] != '1' # Only individuals

  Doctor.find_or_create_by(provider_id: row['NPI']) do |doctor|
    doctor.first_name = row['Provider First Name']
    doctor.last_name = row['Provider Last Name']
    doctor.credential = row['Provider Credential Text']
    doctor.specialty = row['Healthcare Provider Taxonomy Code_1']
    # ... more fields
  end
end
```

### 4. Real-time Provider Validation
**Recommended:** CMS API
- Verify NPI exists and is active
- Get current provider details

### 5. Provider Directory with Local Cache
**Recommended:** Hybrid approach
1. Initial import from CSV file
2. Weekly updates from CSV incremental files
3. Real-time verification via API when needed

---

## Code Examples

### Ruby: Search CMS API

```ruby
require 'net/http'
require 'json'

class NpiSearch
  API_BASE = 'https://npiregistry.cms.hhs.gov/api/'

  def self.search(first_name:, last_name:, state: nil, limit: 10)
    params = {
      version: '2.1',
      first_name: first_name,
      last_name: last_name,
      state: state,
      limit: limit
    }.compact

    uri = URI(API_BASE)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data['results'] || []
  end

  def self.by_npi(npi)
    params = { version: '2.1', number: npi }
    uri = URI(API_BASE)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data['results']&.first
  end
end

# Usage:
providers = NpiSearch.search(first_name: 'John', last_name: 'Smith', state: 'CA')
provider = NpiSearch.by_npi('1234567890')
```

### JavaScript: NLM Autocomplete

```javascript
async function searchProviders(searchTerm) {
  const url = `https://clinicaltables.nlm.nih.gov/api/npi_idv/v3/search?terms=${encodeURIComponent(searchTerm)}&maxList=10`;

  const response = await fetch(url);
  const [count, npis, extra, displayStrings] = await response.json();

  return displayStrings.map((display, index) => ({
    npi: npis[index],
    display: display
  }));
}

// Usage:
const results = await searchProviders('smith boston');
// Results: [{ npi: '1760880173', display: '1760880173 - JOHN SMITH...' }]
```

---

## Resources

- **CMS NPI Registry**: https://npiregistry.cms.hhs.gov/
- **API Documentation**: https://npiregistry.cms.hhs.gov/api-page
- **API Demo**: https://npiregistry.cms.hhs.gov/demo-api
- **Download Files**: https://download.cms.gov/nppes/NPI_Files.html
- **NLM Clinical Tables**: https://clinicaltables.nlm.nih.gov/
- **Taxonomy Codes**: https://www.cms.gov/Medicare/Provider-Enrollment-and-Certification/MedicareProviderSupEnroll/Taxonomy

---

## Updates & Maintenance

- **NPPES Data**: Updated daily
- **Downloadable File**: Full file monthly, incremental weekly
- **API Version**: Currently 2.1 (as of 2025)
- **Total Providers**: ~9 million NPIs (individual and organizational)
- **Data Quality**: Self-reported by providers, validated by CMS

---

## License & Usage

All NPPES data is public domain and free to use. No authentication or API keys required. Data is provided under the Freedom of Information Act (FOIA).

**Attribution**: Data sourced from the National Plan and Provider Enumeration System (NPPES), maintained by the Centers for Medicare & Medicaid Services (CMS).
