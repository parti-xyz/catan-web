class CreateSummaryEmails < ActiveRecord::Migration[4.2]
  def change
    create_table :summary_emails do |t|
      t.references :user, null: false, index: true
      t.string :code, null: false, index: true
      t.datetime :mailed_at
      t.timestamp null: false
    end

    add_index :summary_emails, [:user_id, :code], unique: true
  end
end
