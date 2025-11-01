class CreateClients < ActiveRecord::Migration[7.2]
  def change
    create_table :clients do |t|
      t.string :client_type
      t.string :first_name
      t.string :last_name
      t.string :business_name
      t.string :email
      t.string :phone
      t.date :date_of_birth
      t.string :ssn_encrypted
      t.string :ein
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country
      t.string :status
      t.string :assigned_agent
      t.text :notes

      t.timestamps
    end
    add_index :clients, :client_type
    add_index :clients, :status
  end
end
