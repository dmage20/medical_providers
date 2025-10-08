class CreateOtherNames < ActiveRecord::Migration[7.2]
  def change
    create_table :other_names do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :name_type, limit: 50
      t.string :first_name, limit: 150
      t.string :last_name, limit: 150
      t.string :middle_name, limit: 150
      t.string :name_prefix, limit: 10
      t.string :name_suffix, limit: 10
      t.string :credential, limit: 100
      t.string :organization_name, limit: 300

      t.timestamps
    end

    # Note: index on provider_id is automatically created by t.references
    add_index :other_names, :last_name
    add_index :other_names, :organization_name
  end
end
