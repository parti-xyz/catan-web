class AddBasicToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :basic, :boolean, default: false
  end
end
