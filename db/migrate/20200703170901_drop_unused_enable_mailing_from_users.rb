class DropUnusedEnableMailingFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_columns :users, :enable_mailing_mention
    remove_columns :users, :enable_mailing_pin
    remove_columns :users, :enable_mailing_poll_or_survey
  end
end
