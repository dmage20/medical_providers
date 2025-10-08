json.extract! doctor, :id, :first_name, :last_name, :provider_id, :created_at, :updated_at
json.url doctor_url(doctor, format: :json)
