class AddSortToIssueReaders < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_readers, :sort, :string, default: :stroked
  end
end
