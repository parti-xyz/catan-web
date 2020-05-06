module Choosable
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :choice, in: [:agree, :disagree, :unsure, :neutral], predicates: true, scope: true
    scope :agree, -> { by_choice('agree') }
    scope :disagree, -> { by_choice('disagree') }
    scope :neutral, -> { by_choice('neutral') }
    scope :unsure, -> { by_choice('unsure') }
    scope :sure, -> { where(choice: %w(agree disagree neutral)) }
    scope :by_choice, ->(choice) { where(choice: choice) }
  end

  class_methods do
    def sure?(choice)
      %w(agree disagree neutral).include? choice&.to_s
    end
  end

  def sure?
    self.class.sure?(self.choice)
  end
end
