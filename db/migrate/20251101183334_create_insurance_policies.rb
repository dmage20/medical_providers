class CreateInsurancePolicies < ActiveRecord::Migration[7.2]
  def change
    create_table :insurance_policies do |t|
      t.string :policy_number
      t.string :policy_type
      t.references :client, null: false, foreign_key: true
      t.references :insurance_carrier, null: false, foreign_key: true
      t.date :effective_date
      t.date :expiration_date
      t.decimal :premium_amount, precision: 12, scale: 2
      t.string :premium_frequency
      t.decimal :coverage_amount, precision: 15, scale: 2
      t.decimal :deductible, precision: 10, scale: 2
      t.string :status
      t.string :assigned_agent
      t.text :notes

      t.timestamps
    end
    add_index :insurance_policies, :policy_number
    add_index :insurance_policies, :policy_type
    add_index :insurance_policies, :status
  end
end
