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

ActiveRecord::Schema[8.0].define(version: 2025_11_03_233311) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

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
    t.check_constraint "address_purpose::text = ANY (ARRAY['LOCATION'::character varying::text, 'MAILING'::character varying::text])", name: "check_address_purpose"
    t.check_constraint "address_type::text = ANY (ARRAY['DOM'::character varying::text, 'FGN'::character varying::text])", name: "check_address_type"
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

  create_table "hospital_affiliations", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "hospital_name"
    t.string "hospital_npi"
    t.string "affiliation_type"
    t.string "department"
    t.text "privileges"
    t.date "start_date"
    t.date "end_date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_hospital_affiliations_on_provider_id"
    t.index ["status"], name: "index_hospital_affiliations_on_status"
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

  create_table "insurance_carriers", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "carrier_type"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "website"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.string "rating"
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_insurance_carriers_on_code"
    t.index ["status"], name: "index_insurance_carriers_on_status"
  end

  create_table "insurance_plans", force: :cascade do |t|
    t.string "plan_name"
    t.string "carrier_name"
    t.string "plan_type"
    t.string "network_type"
    t.string "coverage_area"
    t.string "status"
    t.date "effective_date"
    t.date "termination_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_insurance_plans_on_status"
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

  create_table "provider_credentials", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "credential_type"
    t.string "credential_number"
    t.string "issuing_organization"
    t.date "issue_date"
    t.date "expiration_date"
    t.string "status"
    t.date "verification_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_credentials_on_provider_id"
    t.index ["status"], name: "index_provider_credentials_on_status"
  end

  create_table "provider_insurance_plans", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "insurance_plan_id", null: false
    t.boolean "accepts_new_patients"
    t.date "effective_date"
    t.date "termination_date"
    t.string "status"
    t.string "network_tier"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["insurance_plan_id"], name: "index_provider_insurance_plans_on_insurance_plan_id"
    t.index ["provider_id"], name: "index_provider_insurance_plans_on_provider_id"
  end

  create_table "provider_languages", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "language_code"
    t.string "language_name"
    t.string "proficiency_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_languages_on_provider_id"
  end

  create_table "provider_network_memberships", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "provider_network_id", null: false
    t.date "member_since"
    t.date "termination_date"
    t.string "status"
    t.string "tier_level"
    t.boolean "accepts_new_patients"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_network_memberships_on_provider_id"
    t.index ["provider_network_id"], name: "index_provider_network_memberships_on_provider_network_id"
    t.index ["status"], name: "index_provider_network_memberships_on_status"
  end

  create_table "provider_networks", force: :cascade do |t|
    t.string "network_name"
    t.string "network_type"
    t.string "carrier_name"
    t.string "coverage_area"
    t.string "status"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_provider_networks_on_status"
  end

  create_table "provider_practice_infos", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "practice_name"
    t.boolean "accepts_new_patients"
    t.string "patient_age_range"
    t.text "languages_spoken"
    t.text "office_hours"
    t.text "accessibility_features"
    t.boolean "telehealth_available"
    t.string "appointment_wait_time"
    t.date "last_verified"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_practice_infos_on_provider_id"
  end

  create_table "provider_quality_metrics", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "metric_type"
    t.string "metric_name"
    t.decimal "score"
    t.string "rating"
    t.date "measurement_date"
    t.string "source"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_quality_metrics_on_provider_id"
  end

  create_table "provider_specializations", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.string "specialization_name"
    t.string "focus_area"
    t.integer "years_experience"
    t.boolean "board_certified"
    t.string "certification_body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_specializations_on_provider_id"
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
    t.check_constraint "(gender::text = ANY (ARRAY['M'::character varying::text, 'F'::character varying::text, 'X'::character varying::text])) OR gender IS NULL", name: "check_gender"
    t.check_constraint "entity_type = ANY (ARRAY[1, 2])", name: "check_entity_type"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "addresses", "cities"
  add_foreign_key "addresses", "providers"
  add_foreign_key "addresses", "states"
  add_foreign_key "authorized_officials", "providers"
  add_foreign_key "cities", "states"
  add_foreign_key "endpoints", "providers"
  add_foreign_key "hospital_affiliations", "providers"
  add_foreign_key "identifiers", "providers"
  add_foreign_key "identifiers", "states"
  add_foreign_key "other_names", "providers"
  add_foreign_key "provider_credentials", "providers"
  add_foreign_key "provider_insurance_plans", "insurance_plans"
  add_foreign_key "provider_insurance_plans", "providers"
  add_foreign_key "provider_languages", "providers"
  add_foreign_key "provider_network_memberships", "provider_networks"
  add_foreign_key "provider_network_memberships", "providers"
  add_foreign_key "provider_practice_infos", "providers"
  add_foreign_key "provider_quality_metrics", "providers"
  add_foreign_key "provider_specializations", "providers"
  add_foreign_key "provider_taxonomies", "providers"
  add_foreign_key "provider_taxonomies", "states", column: "license_state_id"
  add_foreign_key "provider_taxonomies", "taxonomies"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
