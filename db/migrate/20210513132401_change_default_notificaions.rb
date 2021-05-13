class ChangeDefaultNotificaions < ActiveRecord::Migration[5.2]
  def change
    %i[payoff_create_comment payoff_create_post payoff_pin_post payoff_create_issue].each do |column_name|
      change_column_default(:root_observations, column_name, 'subscribing_and_app_push')
    end

    %i[payoff_create_comment payoff_create_post payoff_pin_post payoff_create_issue].each do |column_name|
      change_column_default(:group_observations, column_name, 'subscribing_and_app_push')
    end

    %i[payoff_create_comment payoff_create_post payoff_pin_post].each do |column_name|
      change_column_default(:issue_observations, column_name, 'subscribing_and_app_push')
    end

    %i[payoff_create_comment].each do |column_name|
      change_column_default(:post_observations, column_name, 'subscribing_and_app_push')
    end
  end
end
