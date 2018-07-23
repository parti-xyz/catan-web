class CreateSummaryEmails < ActiveRecord::Migration[4.2]
  def change
    create_table :summary_emails, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC" do |t|
      t.references :user, null: false, index: true
      t.string :code, null: false, index: true
      t.datetime :mailed_at
      t.timestamp null: false
    end

    add_index :summary_emails, [:user_id, :code], unique: true
  end
end
