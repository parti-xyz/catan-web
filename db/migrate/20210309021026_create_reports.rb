class CreateReports < ActiveRecord::Migration[5.2]
  def change
    create_table :reports do |t|
      t.references :reportable, null: false, index: true, polymorphic: true
      t.references :user, null: false, index: true
      t.string :reason, null: false, default: 'etc'
      t.timestamps null: false
    end
  end
end
