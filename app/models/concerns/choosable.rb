module Choosable
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :choice, in: [:agree, :disagree, :unsure, :neutral], predicates: true, scope: true
    scope :agreed, -> { by_choice('agree') }
    scope :disagreed, -> { by_choice('disagree') }
    scope :neutral, -> { by_choid('neutral') }
    scope :unsure, -> { by_choice('unsure') }
    scope :sure, -> { where(choice: %w(agree disagree neutral)) }
    scope :by_choice, ->(choice) { where(choice: choice) }
  end
end
