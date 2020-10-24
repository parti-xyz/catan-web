class MigrateTalksToInitialSection < ActiveRecord::Migration[4.2]
  class Talk < ApplicationRecord
    acts_as_paranoid
  end

  def up
    ActiveRecord::Base.transaction do
      Issue.all.each do |issue|
        issue.talks.update_all section_id: issue.sections.find_by(initial: true)
      end

      Talk.with_deleted.where(section_id: nil).update_all section_id: -1
    end

    change_column_null :talks, :section_id, false
  end
end
