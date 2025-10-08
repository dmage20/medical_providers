class EnablePostgresqlExtensions < ActiveRecord::Migration[7.2]
  def change
    # Enable pg_trgm extension for fuzzy string matching and trigram-based similarity
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
  end
end
