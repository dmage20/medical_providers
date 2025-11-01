class CreatePremia < ActiveRecord::Migration[7.2]
  def change
    create_table :premia do |t|
      t.references :insurance_policy, null: false, foreign_key: true
      t.date :payment_date
      t.date :due_date
      t.decimal :amount
      t.string :payment_method
      t.string :payment_status
      t.string :transaction_id
      t.text :notes

      t.timestamps
    end
    add_index :premia, :payment_status
  end
end
