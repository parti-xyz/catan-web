class MessageConfiguration::RootObservation < ApplicationRecord
  include MessageObservationConfigurable

  belongs_to :group
  validates :group_id, uniqueness: true

  def observable?(action, payoffs)
    return false if payoffs.blank?

    current_code = try(:"payoff_#{action}")
    unless current_code.nil?
      current_code = MessageObservationConfigurable.default_payoff(action)
    end

    if payoffs.kind_of?(Array)
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
end
