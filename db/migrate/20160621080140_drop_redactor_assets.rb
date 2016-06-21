class DropRedactorAssets < ActiveRecord::Migration
  def up
    drop_table :redactor_assets
  end

  def down
  end
end
