module MessageObservationConfigurable
  extend ActiveSupport::Concern

  # 어떤 범위에서 가능한 설정인지
  ACTIONS_PER_POST = %i[create_comment closed_survey]
  ACTIONS_PER_ISSUE = %i[create_post pin_post]
  ACTIONS_PER_GROUP = %i[mention upvote create_issue update_issue_title]

  included do
    extend Enumerize
    payoff_actions.each do |action|
      enumerize :"payoff_#{action}", in: [:subscribing, :subscribing_and_app_push, :ignoring], predicates: true, scope: true, i18n_scope: 'enumerize.defaults.payoff'
    end

    def all_configurations
      results = self.class.payoff_column_names.map do |column_name|
        action = MessageObservationConfigurable.payoff_column_name_to_action(column_name)
        [action.to_sym, overrided_payoff(action)]
      end.to_h

      # sort
      [ACTIONS_PER_GROUP, ACTIONS_PER_ISSUE, ACTIONS_PER_POST].flatten.map do |action|
        next unless self.class.payoff_column_names.include?(MessageObservationConfigurable.payoff_action_to_column_name(action))
        [action, results[action]]
      end.compact.to_h
    end

    def overrided_payoff(action)
      column_name = MessageObservationConfigurable.payoff_action_to_column_name(action)

      current_payoff = send(column_name.to_sym)
      return current_payoff.to_sym if self.persisted? && current_payoff.present?

      return parent.overrided_payoff(action) if parent.present?

      MessageObservationConfigurable.default_payoff(action)
    end

    def inherit_payoffs
      all_configurations.each do |action, payoff|
        column_name = MessageObservationConfigurable.payoff_action_to_column_name(action)

        send(:"#{column_name}=", payoff)
      end
    end
  end

  class_methods do
    def payoff_column_names
      column_names.grep(/^payoff_[a-z_]*$/)
    end

    def payoff_actions
      payoff_column_names.map { |column_name| MessageObservationConfigurable.payoff_column_name_to_action(column_name) }
    end
  end

  def self.payoff_column_name_to_action(column_name)
    column_name.delete_prefix('payoff_')
  end

  def self.payoff_action_to_column_name(action)
    "payoff_#{action}"
  end

  def self.all_payoff_column_names_permitted
    [
      ACTIONS_PER_POST,
      ACTIONS_PER_ISSUE,
      ACTIONS_PER_GROUP
    ].flatten.map do |action|
      payoff_action_to_column_name(action)
    end
  end

  def self.default_payoff(action)
    return :subscribing_and_app_push if %i[new_issue mention upvote].include?(action.to_sym)

    :ignoring
  end

  def self.all_subscribing_payoffs
    [:subscribing, :subscribing_and_app_push]
  end

  def self.all_app_push_payoffs
    [:subscribing_and_app_push]
  end
end
