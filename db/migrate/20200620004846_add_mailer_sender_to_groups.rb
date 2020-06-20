class AddMailerSenderToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :mailer_sender, :string
  end
end
