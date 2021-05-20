class MessageConfiguration::RootObservation < ApplicationRecord
  include MessageObservationConfigurable

  belongs_to :group
  validates :group_id, uniqueness: true

  def observable?(action, payoffs)
    return false if payoffs.blank?

    current_code = try(:"payoff_#{action}") || MessageConfiguration::RootObservation.default_payoff(action)
    current_code = current_code&.to_sym
    if payoffs.is_a?(Array)
      payoffs.include?(current_code)
    else
      payoffs == current_code
    end
  end

  def self.of(group)
    find_or_initialize_by(group_id: group.id) if group.present?
  end

  def parent
    nil
  end

  def self.parent_class
    nil
  end
end
