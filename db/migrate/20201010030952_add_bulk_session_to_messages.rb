class AddBulkSessionToMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :bulk_session, :string
  end
end
