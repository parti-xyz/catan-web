class AddPlanToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :plan, :string

    reversible do |dir|
      dir.up do
        query = "UPDATE groups SET plan = 'lite'"
        ActiveRecord::Base.connection.execute query
        say query

        query = "UPDATE groups SET plan = 'premium' where slug in ('indie', 'union')"
        ActiveRecord::Base.connection.execute query
        say query

        change_column_null :groups, :plan, false
      end
    end
  end
end
