class AddActionToMessages < ActiveRecord::Migration
  def change
    # add_column :messages, :action, :string
    # add_column :messages, :action_params, :text
    add_reference :messages, :sender, null: false, index: true

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.transaction do
          Message.all.each do |message|
            if message.messagable.present?
              message.sender = message.messagable.sender_of_message(message)
              message.save!
            end
          end
        end
      end
    end
  end
end
