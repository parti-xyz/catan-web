class AddInitialToSections < ActiveRecord::Migration[4.2]
  def change
    add_column :sections, :initial, :boolean, default: false

    reversible do |dir|
      dir.up do
        query = <<-SQL.squish
          UPDATE sections
             SET initial = true
        SQL
        ActiveRecord::Base.connection.execute query
        say query
      end
    end

  end
end
