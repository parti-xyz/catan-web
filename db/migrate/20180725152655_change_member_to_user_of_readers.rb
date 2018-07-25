class ChangeMemberToUserOfReaders < ActiveRecord::Migration[5.2]
  def change
    add_reference :readers, :user, index: true
    rename_column :readers, :member_id, :deprecated_member_id

    reversible do |dir|
      dir.up do
        transaction do
          Reader.all.each do |reader|
            user = reader.deprecated_member.user
            if Reader.where(post: reader.post, user: user).where.not(id: reader.id).count > 0
              reader.destroy!
            else
              reader.update_attributes!(user: user)
            end
          end
        end
      end
    end

    change_column_null :readers, :user_id, false
    change_column_null :readers, :deprecated_member_id, true
  end
end
