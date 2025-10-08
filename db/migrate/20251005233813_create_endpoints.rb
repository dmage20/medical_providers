class CreateEndpoints < ActiveRecord::Migration[7.2]
  def change
    create_table :endpoints do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :endpoint_url, null: false, limit: 500
      t.string :endpoint_type, limit: 50
      t.text :endpoint_description
      t.string :content_type, limit: 100
      t.string :use_type, limit: 50
      t.boolean :affiliation, default: false

      t.timestamps
    end

    # Note: index on provider_id is automatically created by t.references
    add_index :endpoints, :endpoint_type
  end
end
