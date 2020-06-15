class ChangeEnableMailingDefaultFalseOfUsers < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:users, :enable_mailing_summary, true)
    change_column_default(:users, :enable_mailing_mention, false)
    change_column_default(:users, :enable_mailing_pin, false)
    change_column_default(:users, :enable_mailing_poll_or_survey, false)
    change_column_default(:users, :enable_mailing_member, false)
  end
end

