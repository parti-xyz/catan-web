class CreateIssueReaders < ActiveRecord::Migration[5.2]
  def change
    create_table :issue_readers do |t|
      t.references :user, null: false, index: true
      t.references :issue, null: false, index: true
      t.timestamps null: false
    end
  end
end
