class DropTitleFromTalks < ActiveRecord::Migration[4.2]
  class Talk < ApplicationRecord
  end

  def up
    ActiveRecord::Base.transaction do
      Talk.all.each do |talk|
        double_situation = (talk.title == talk.body.try(:lines).try(:first).try(:strip).try(:truncate, Note::LIMIT_CHAR))
        unless double_situation
          talk.body = "<p data='migrated-from-title'>#{talk.title}</p>\r\n#{talk.body}"
          talk.body.strip!
          talk.save!
        end
      end
    end
    remove_column :talks, :title
  end
end
