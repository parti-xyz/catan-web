class CreateGroupHomeComponents < ActiveRecord::Migration[5.2]
  def change
    create_table :group_home_components do |t|
      t.references :group, index: true, null: false
      t.string :title, null: false
      t.string :format_name, null: false
      t.integer :seq_no, null: false
      t.timestamp null: false
    end
  end
end
