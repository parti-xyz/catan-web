class AddDeletedAtToModels < ActiveRecord::Migration[4.2]
  def change
    %i(answers articles comments discussions issues opinions posts proposals users).each do |tablename|
      add_column tablename, :deleted_at, :datetime
      add_index tablename, :deleted_at
    end
  end
end
