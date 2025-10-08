# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Clear existing data (in development only)
if Rails.env.development?
  puts "Clearing existing providers..."
  Provider.destroy_all
  City.destroy_all
end

# Get some states and taxonomies
ca = State.find_by(code: "CA")
ny = State.find_by(code: "NY")
tx = State.find_by(code: "TX")
ma = State.find_by(code: "MA")

family_medicine = Taxonomy.find_by(code: "207Q00000X")
internal_medicine = Taxonomy.find_by(code: "207R00000X")
pediatrics = Taxonomy.find_by(code: "208000000X")
nurse_practitioner = Taxonomy.find_by(code: "363L00000X")
physician_assistant = Taxonomy.find_by(code: "363A00000X")

# Create some cities
boston = City.find_or_create_by!(name: "Boston", state: ma)
los_angeles = City.find_or_create_by!(name: "Los Angeles", state: ca)
san_francisco = City.find_or_create_by!(name: "San Francisco", state: ca)
new_york = City.find_or_create_by!(name: "New York", state: ny)
houston = City.find_or_create_by!(name: "Houston", state: tx)

puts "Creating sample providers..."

# Provider 1: Dr. Sarah Johnson - Family Medicine in Boston
provider1 = Provider.create!(
  npi: "1234567890",
  entity_type: 1,
  first_name: "Sarah",
  last_name: "Johnson",
  middle_name: "Marie",
  credential: "MD",
  gender: "F",
  enumeration_date: 10.years.ago
)

provider1.addresses.create!(
  address_purpose: "LOCATION",
  address_1: "123 Medical Plaza",
  address_2: "Suite 200",
  city: boston,
  city_name: "Boston",
  state: ma,
  postal_code: "02101",
  telephone: "617-555-1234"
)

provider1.provider_taxonomies.create!(
  taxonomy: family_medicine,
  license_number: "MD12345",
  license_state: ma,
  is_primary: true
)

# Provider 2: Dr. Michael Chen - Internal Medicine in Los Angeles
provider2 = Provider.create!(
  npi: "2345678901",
  entity_type: 1,
  first_name: "Michael",
  last_name: "Chen",
  credential: "DO",
  gender: "M",
  enumeration_date: 8.years.ago
)

provider2.addresses.create!(
  address_purpose: "LOCATION",
  address_1: "456 Healthcare Ave",
  city: los_angeles,
  city_name: "Los Angeles",
  state: ca,
  postal_code: "90001",
  telephone: "213-555-5678"
)

provider2.provider_taxonomies.create!(
  taxonomy: internal_medicine,
  license_number: "CA98765",
  license_state: ca,
  is_primary: true
)

# Provider 3: Jennifer Martinez, NP - Nurse Practitioner in San Francisco
provider3 = Provider.create!(
  npi: "3456789012",
  entity_type: 1,
  first_name: "Jennifer",
  last_name: "Martinez",
  credential: "NP",
  gender: "F",
  enumeration_date: 5.years.ago
)

provider3.addresses.create!(
  address_purpose: "LOCATION",
  address_1: "789 Mission St",
  address_2: "Floor 3",
  city: san_francisco,
  city_name: "San Francisco",
  state: ca,
  postal_code: "94103",
  telephone: "415-555-9876"
)

provider3.provider_taxonomies.create!(
  taxonomy: nurse_practitioner,
  license_number: "NP55555",
  license_state: ca,
  is_primary: true
)

# Provider 4: Dr. Robert Williams - Pediatrics in New York
provider4 = Provider.create!(
  npi: "4567890123",
  entity_type: 1,
  first_name: "Robert",
  last_name: "Williams",
  middle_name: "James",
  name_prefix: "Dr.",
  credential: "MD",
  gender: "M",
  enumeration_date: 15.years.ago
)

provider4.addresses.create!(
  address_purpose: "LOCATION",
  address_1: "321 Park Avenue",
  city: new_york,
  city_name: "New York",
  state: ny,
  postal_code: "10022",
  telephone: "212-555-3456"
)

provider4.provider_taxonomies.create!(
  taxonomy: pediatrics,
  license_number: "NY11111",
  license_state: ny,
  is_primary: true
)

# Provider 5: David Thompson, PA - Physician Assistant in Houston
provider5 = Provider.create!(
  npi: "5678901234",
  entity_type: 1,
  first_name: "David",
  last_name: "Thompson",
  credential: "PA-C",
  gender: "M",
  enumeration_date: 3.years.ago
)

provider5.addresses.create!(
  address_purpose: "LOCATION",
  address_1: "555 Medical Center Blvd",
  city: houston,
  city_name: "Houston",
  state: tx,
  postal_code: "77001",
  telephone: "713-555-7890"
)

provider5.provider_taxonomies.create!(
  taxonomy: physician_assistant,
  license_number: "TX44444",
  license_state: tx,
  is_primary: true
)

# Provider 6: Organization - City Hospital in Boston
provider6 = Provider.create!(
  npi: "6789012345",
  entity_type: 2,
  organization_name: "City Hospital Boston",
  enumeration_date: 25.years.ago
)

provider6.addresses.create!(
  address_purpose: "LOCATION",
  address_1: "1000 Hospital Drive",
  city: boston,
  city_name: "Boston",
  state: ma,
  postal_code: "02115",
  telephone: "617-555-0000"
)

general_hospital = Taxonomy.find_by(code: "282N00000X")
provider6.provider_taxonomies.create!(
  taxonomy: general_hospital,
  is_primary: true
) if general_hospital

provider6.create_authorized_official!(
  first_name: "James",
  last_name: "Anderson",
  title_or_position: "CEO",
  telephone: "617-555-0001"
)

puts "Created #{Provider.count} providers"
puts "Created #{Address.count} addresses"
puts "Created #{ProviderTaxonomy.count} provider-taxonomy relationships"
puts "Created #{City.count} cities"
puts "Seeding complete!"
