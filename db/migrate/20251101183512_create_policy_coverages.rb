class CreatePolicyCoverages < ActiveRecord::Migration[7.2]
  def change
    create_table :policy_coverages do |t|
      t.references :insurance_policy, null: false, foreign_key: true
      t.string :coverage_type
      t.string :coverage_name
      t.decimal :coverage_limit
      t.decimal :deductible
      t.decimal :premium_amount
      t.text :description
      t.string :status

      t.timestamps
    end
  end
end
