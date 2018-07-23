class ChangeEnableMailingOfUsers < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :enable_mailing, :enable_mailing_summary
    add_column :users, :enable_mailing_mention, :boolean, default: true
    add_column :users, :enable_mailing_pin, :boolean, default: true
    add_column :users, :enable_mailing_poll_or_survey, :boolean, default: true

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.connection.execute "UPDATE users SET enable_mailing_mention = enable_mailing_summary"
        ActiveRecord::Base.connection.execute "UPDATE users SET enable_mailing_pin = enable_mailing_summary"
        ActiveRecord::Base.connection.execute "UPDATE users SET enable_mailing_poll_or_survey = enable_mailing_summary"
      end
    end
  end
end
