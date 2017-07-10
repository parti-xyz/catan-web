class AddStatusToWiki < ActiveRecord::Migration
  def change
    add_column :wikis, :status, :string, null: false, default: 'active'
  end
end
