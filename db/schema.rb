# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_10_05_233815) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "address_purpose", limit: 10, null: false
    t.string "address_type", limit: 3, default: "DOM"
    t.string "address_1", limit: 300
    t.string "address_2", limit: 300
    t.bigint "city_id"
    t.string "city_name", limit: 200
    t.bigint "state_id"
    t.string "postal_code", limit: 20
    t.string "country_code", limit: 2, default: "US"
    t.string "telephone", limit: 20
    t.string "fax", limit: 20
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_purpose"], name: "index_addresses_on_address_purpose"
    t.index ["city_id"], name: "index_addresses_on_city_id"
    t.index ["postal_code"], name: "index_addresses_on_postal_code"
    t.index ["provider_id", "address_purpose"], name: "index_addresses_on_provider_id_and_address_purpose"
    t.index ["provider_id"], name: "index_addresses_on_provider_id"
    t.index ["state_id", "city_id", "address_purpose"], name: "index_addresses_location_search", where: "((address_purpose)::text = 'LOCATION'::text)"
    t.index ["state_id"], name: "index_addresses_on_state_id"
    t.check_constraint "address_purpose::text = ANY (ARRAY['LOCATION'::character varying, 'MAILING'::character varying]::text[])", name: "check_address_purpose"
    t.check_constraint "address_type::text = ANY (ARRAY['DOM'::character varying, 'FGN'::character varying]::text[])", name: "check_address_type"
  end

  create_table "authorized_officials", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "first_name", limit: 150, null: false
    t.string "last_name", limit: 150, null: false
    t.string "middle_name", limit: 150
    t.string "name_prefix", limit: 10
    t.string "name_suffix", limit: 10
    t.string "credential", limit: 100
    t.string "title_or_position", limit: 200
    t.string "telephone", limit: 20
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_authorized_officials_on_provider_id", unique: true
  end

  create_table "cities", force: :cascade do |t|
    t.string "name", limit: 200, null: false
    t.bigint "state_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "state_id"], name: "index_cities_on_name_and_state_id", unique: true
    t.index ["name"], name: "index_cities_on_name"
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "doctors", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "endpoints", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "endpoint_url", limit: 500, null: false
    t.string "endpoint_type", limit: 50
    t.text "endpoint_description"
    t.string "content_type", limit: 100
    t.string "use_type", limit: 50
    t.boolean "affiliation", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint_type"], name: "index_endpoints_on_endpoint_type"
    t.index ["provider_id"], name: "index_endpoints_on_provider_id"
  end

  create_table "identifiers", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "identifier_type", limit: 50, null: false
    t.string "identifier_value", limit: 100, null: false
    t.bigint "state_id"
    t.string "issuer", limit: 200
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier_type", "identifier_value"], name: "index_identifiers_type_value"
    t.index ["identifier_type"], name: "index_identifiers_on_identifier_type"
    t.index ["identifier_value"], name: "index_identifiers_on_identifier_value"
    t.index ["provider_id", "identifier_type", "identifier_value"], name: "index_identifiers_unique", unique: true
    t.index ["provider_id"], name: "index_identifiers_on_provider_id"
    t.index ["state_id"], name: "index_identifiers_on_state_id"
  end

  create_table "other_names", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "name_type", limit: 50
    t.string "first_name", limit: 150
    t.string "last_name", limit: 150
    t.string "middle_name", limit: 150
    t.string "name_prefix", limit: 10
    t.string "name_suffix", limit: 10
    t.string "credential", limit: 100
    t.string "organization_name", limit: 300
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_name"], name: "index_other_names_on_last_name"
    t.index ["organization_name"], name: "index_other_names_on_organization_name"
    t.index ["provider_id"], name: "index_other_names_on_provider_id"
  end

  create_table "provider_taxonomies", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "taxonomy_id", null: false
    t.string "license_number", limit: 100
    t.bigint "license_state_id"
    t.boolean "is_primary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["license_state_id"], name: "index_provider_taxonomies_on_license_state_id"
    t.index ["provider_id", "is_primary"], name: "index_provider_taxonomies_on_provider_id_and_is_primary", where: "(is_primary = true)"
    t.index ["provider_id", "taxonomy_id"], name: "index_provider_taxonomies_on_provider_id_and_taxonomy_id", unique: true
    t.index ["provider_id"], name: "index_provider_taxonomies_on_provider_id"
    t.index ["provider_id"], name: "index_provider_taxonomies_one_primary", unique: true, where: "(is_primary = true)"
    t.index ["taxonomy_id"], name: "index_provider_taxonomies_on_taxonomy_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "npi", limit: 10, null: false
    t.integer "entity_type", limit: 2, null: false
    t.string "replacement_npi", limit: 10
    t.string "first_name", limit: 150
    t.string "last_name", limit: 150
    t.string "middle_name", limit: 150
    t.string "name_prefix", limit: 10
    t.string "name_suffix", limit: 10
    t.string "credential", limit: 100
    t.string "gender", limit: 1
    t.string "organization_name", limit: 300
    t.boolean "organization_subpart", default: false
    t.string "ein", limit: 9
    t.boolean "sole_proprietor", default: false
    t.date "enumeration_date"
    t.date "last_update_date"
    t.date "deactivation_date"
    t.string "deactivation_reason", limit: 100
    t.date "reactivation_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "search_vector", type: :tsvector, as: "(((setweight(to_tsvector('english'::regconfig, (COALESCE(first_name, ''::character varying))::text), 'A'::\"char\") || setweight(to_tsvector('english'::regconfig, (COALESCE(last_name, ''::character varying))::text), 'A'::\"char\")) || setweight(to_tsvector('english'::regconfig, (COALESCE(organization_name, ''::character varying))::text), 'A'::\"char\")) || setweight(to_tsvector('english'::regconfig, (COALESCE(credential, ''::character varying))::text), 'B'::\"char\"))", stored: true
    t.index ["credential"], name: "index_providers_on_credential"
    t.index ["deactivation_date"], name: "index_providers_on_deactivation_date"
    t.index ["entity_type"], name: "index_providers_on_entity_type"
    t.index ["last_name", "first_name", "credential"], name: "index_providers_name_credential", where: "((entity_type = 1) AND (deactivation_date IS NULL))"
    t.index ["last_name", "first_name"], name: "index_providers_active_individuals", where: "((deactivation_date IS NULL) AND (entity_type = 1))"
    t.index ["last_name"], name: "index_providers_on_last_name", where: "(entity_type = 1)"
    t.index ["npi"], name: "index_providers_on_npi", unique: true
    t.index ["organization_name"], name: "index_providers_on_organization_name", where: "(entity_type = 2)"
    t.index ["search_vector"], name: "index_providers_on_search_vector", using: :gin
    t.check_constraint "(gender::text = ANY (ARRAY['M'::character varying, 'F'::character varying, 'X'::character varying]::text[])) OR gender IS NULL", name: "check_gender"
    t.check_constraint "entity_type = ANY (ARRAY[1, 2])", name: "check_entity_type"
  end

  create_table "states", force: :cascade do |t|
    t.string "code", limit: 2, null: false
    t.string "name", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_states_on_code", unique: true
  end

  create_table "taxonomies", force: :cascade do |t|
    t.string "code", limit: 10, null: false
    t.string "classification", limit: 200
    t.string "specialization", limit: 200
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classification"], name: "index_taxonomies_on_classification"
    t.index ["code"], name: "index_taxonomies_on_code", unique: true
    t.index ["specialization"], name: "index_taxonomies_on_specialization"
  end

  add_foreign_key "addresses", "cities"
  add_foreign_key "addresses", "providers"
  add_foreign_key "addresses", "states"
  add_foreign_key "authorized_officials", "providers"
  add_foreign_key "cities", "states"
  add_foreign_key "endpoints", "providers"
  add_foreign_key "identifiers", "providers"
  add_foreign_key "identifiers", "states"
  add_foreign_key "other_names", "providers"
  add_foreign_key "provider_taxonomies", "providers"
  add_foreign_key "provider_taxonomies", "states", column: "license_state_id"
  add_foreign_key "provider_taxonomies", "taxonomies"
end
