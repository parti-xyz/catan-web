class DropRedactorAssets < ActiveRecord::Migration[4.2]
  def up
    drop_table :redactor_assets
  end

  def down
  end
end
