class AddSocialCardToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :social_card, :string
  end
end
