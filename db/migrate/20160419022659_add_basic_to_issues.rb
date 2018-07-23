class AddBasicToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :basic, :boolean, default: false
  end
end
