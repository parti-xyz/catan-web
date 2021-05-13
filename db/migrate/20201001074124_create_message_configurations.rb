class CreateMessageConfigurations < ActiveRecord::Migration[5.2]
  ACTIONS_PER_POST = MessageObservationConfigurable::ACTIONS_PER_POST
  ACTIONS_PER_ISSUE = MessageObservationConfigurable::ACTIONS_PER_ISSUE
  ACTIONS_PER_GROUP = MessageObservationConfigurable::ACTIONS_PER_GROUP

  def change
    create_table :root_observations do |t|
      t.references :group, null: false, index: true
      [ ACTIONS_PER_POST, ACTIONS_PER_ISSUE, ACTIONS_PER_GROUP].flatten.each do |action|
        t.string "payoff_#{action}", default: MessageConfiguration::RootObservation.default_payoff(action)
      end
      t.timestamps
    end

    create_table :group_observations do |t|
      t.references :user, null: false, index: true
      t.references :group, null: false, index: true
      [ ACTIONS_PER_POST, ACTIONS_PER_ISSUE, ACTIONS_PER_GROUP].flatten.each do |action|
        t.string "payoff_#{action}", default: MessageConfiguration::GroupObservation.default_payoff(action)
      end
      t.timestamps
    end

    create_table :issue_observations do |t|
      t.references :user, null: false, index: true
      t.references :issue, null: false, index: true
      [ ACTIONS_PER_POST, ACTIONS_PER_ISSUE].flatten.each do |action|
        t.string "payoff_#{action}", default: MessageConfiguration::IssueObservation.default_payoff(action)
      end
      t.timestamps
    end

    create_table :post_observations do |t|
      t.references :user, null: false, index: true
      t.references :post, null: false, index: true
      ACTIONS_PER_POST.each do |action|
        t.string "payoff_#{action}", default: MessageConfiguration::PostObservation.default_payoff(action)
      end
      t.timestamps
    end
  end
end
