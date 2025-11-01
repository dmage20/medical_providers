class CreateClaims < ActiveRecord::Migration[7.2]
  def change
    create_table :claims do |t|
      t.string :claim_number
      t.references :insurance_policy, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.date :claim_date
      t.string :claim_type
      t.decimal :claim_amount
      t.decimal :settlement_amount
      t.string :status
      t.date :filed_date
      t.date :settlement_date
      t.text :description
      t.text :notes

      t.timestamps
    end
    add_index :claims, :claim_number
    add_index :claims, :status
  end
end
