class CreatePolicyDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :policy_documents do |t|
      t.references :insurance_policy, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :document_type
      t.string :document_name
      t.string :file_url
      t.integer :file_size
      t.date :uploaded_date
      t.text :description
      t.string :status

      t.timestamps
    end
  end
end
