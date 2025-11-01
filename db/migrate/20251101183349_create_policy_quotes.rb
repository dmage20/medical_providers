class CreatePolicyQuotes < ActiveRecord::Migration[7.2]
  def change
    create_table :policy_quotes do |t|
      t.string :quote_number
      t.references :client, null: false, foreign_key: true
      t.references :insurance_carrier, null: false, foreign_key: true
      t.string :policy_type
      t.decimal :quoted_premium
      t.decimal :coverage_amount
      t.decimal :deductible
      t.date :quote_date
      t.date :expiration_date
      t.string :status
      t.string :assigned_agent
      t.text :notes

      t.timestamps
    end
    add_index :policy_quotes, :quote_number
    add_index :policy_quotes, :status
  end
end
