class AddBlindToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :blind, :boolean, default: false

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.transaction do
          Blind.all.each do |blind|
            BlindJob.new.perform(blind.id)
          end
        end
      end
    end
  end
end
