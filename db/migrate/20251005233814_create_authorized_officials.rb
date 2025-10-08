class CreateAuthorizedOfficials < ActiveRecord::Migration[7.2]
  def change
    create_table :authorized_officials do |t|
      t.references :provider, null: false, foreign_key: true, index: { unique: true }
      t.string :first_name, null: false, limit: 150
      t.string :last_name, null: false, limit: 150
      t.string :middle_name, limit: 150
      t.string :name_prefix, limit: 10
      t.string :name_suffix, limit: 10
      t.string :credential, limit: 100
      t.string :title_or_position, limit: 200
      t.string :telephone, limit: 20

      t.timestamps
    end

    # Note: unique index on provider_id is already created by t.references with index: { unique: true }
  end
end
