class DropMailerSenderFromGroups < ActiveRecord::Migration[5.2]
  def change
    remove_columns :groups, :mailer_sender
  end
end
