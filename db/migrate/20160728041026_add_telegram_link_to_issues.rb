class AddTelegramLinkToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :telegram_link, :string
  end
end
