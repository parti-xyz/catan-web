class MigrationMeetingsForMentionAction < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<-EOS
          UPDATE     `messages`
          INNER JOIN `mentions`
          ON         (mentions.user_id = messages.user_id
                     AND mentions.mentionable_id = messages.messagable_id
                     AND mentions.mentionable_type = messages.messagable_type)
          SET        `messages`.`action` = 'mention'
        EOS
      end
      dir.down do
        execute <<-EOS
          UPDATE `messages` SET `messages`.`action` = NULL WHERE `messages`.`action` = 'mention'
        EOS
      end
    end
  end
end
