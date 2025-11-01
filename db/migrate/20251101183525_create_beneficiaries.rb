class CreateBeneficiaries < ActiveRecord::Migration[7.2]
  def change
    create_table :beneficiaries do |t|
      t.references :insurance_policy, null: false, foreign_key: true
      t.string :beneficiary_type
      t.string :first_name
      t.string :last_name
      t.string :relationship
      t.decimal :percentage
      t.date :date_of_birth
      t.string :ssn_encrypted
      t.text :contact_info

      t.timestamps
    end
  end
end
