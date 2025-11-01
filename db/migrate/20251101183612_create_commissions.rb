class CreateCommissions < ActiveRecord::Migration[7.2]
  def change
    create_table :commissions do |t|
      t.references :insurance_policy, null: false, foreign_key: true
      t.string :agent_name
      t.string :commission_type
      t.decimal :commission_rate
      t.decimal :commission_amount
      t.date :payment_date
      t.date :period_start
      t.date :period_end
      t.string :status
      t.text :notes

      t.timestamps
    end
    add_index :commissions, :status
  end
end
