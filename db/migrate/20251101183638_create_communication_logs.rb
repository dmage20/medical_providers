class CreateCommunicationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :communication_logs do |t|
      t.references :client, null: false, foreign_key: true
      t.references :lead, null: false, foreign_key: true
      t.string :communication_type
      t.datetime :communication_date
      t.string :subject
      t.text :content
      t.string :direction
      t.string :agent_name
      t.boolean :follow_up_required
      t.date :follow_up_date

      t.timestamps
    end
  end
end
