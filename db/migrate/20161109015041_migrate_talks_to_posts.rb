class MigrateTalksToPosts < ActiveRecord::Migration[4.2]
  class Talk < ApplicationRecord
  end

  def up
    add_column :posts, :body, :text
    add_column :posts, :section_id, :integer, index: true
    add_reference :posts, :reference, polymorphic: true, index: true
    add_reference :posts, :poll, index: true
    add_index :posts, ["id", "reference_id", "reference_type"], unique: true

    ActiveRecord::Base.transaction do
      Talk.all.each do |talk|
        post = talk.acting_as
        post.update_columns(
          body: talk.body, section_id: talk.section_id,
          reference_id: talk.reference_id, reference_type: talk.reference_type,
          poll_id: talk.poll_id)
      end
    end
  end

  def down
    raise '원복불가'
  end
end
