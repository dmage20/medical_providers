class AddIndexesToProviderTables < ActiveRecord::Migration[7.2]
  def change
    # Most indexes are already defined in the create_table migrations
    # This migration is reserved for any additional performance indexes discovered later

    # Example: Add covering index for provider listings (reduce table lookups)
    # add_index :providers, [:id, :npi, :first_name, :last_name, :credential],
    #   where: "deactivation_date IS NULL",
    #   name: 'index_providers_basic_info'
  end
end
