class CreateLeads < ActiveRecord::Migration[7.2]
  def change
    create_table :leads do |t|
      t.string :source
      t.string :first_name
      t.string :last_name
      t.string :business_name
      t.string :email
      t.string :phone
      t.string :interest_type
      t.string :status
      t.string :assigned_agent
      t.date :contact_date
      t.date :follow_up_date
      t.text :notes
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
    add_index :leads, :status
  end
end
