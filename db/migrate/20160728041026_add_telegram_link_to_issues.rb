class AddTelegramLinkToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :telegram_link, :string
  end
end
