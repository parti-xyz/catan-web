module Choosable
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :choice, in: [:agree, :disagree, :unsure], predicates: true, scope: true
    scope :agreed, -> { by_choice('agree') }
    scope :disagreed, -> { by_choice('disagree') }
    scope :unsure, -> { by_choice('unsure') }
    scope :sure, -> { where(choice: %w(agree disagree)) }
    scope :by_choice, ->(choice) { where(choice: choice) }
  end
end
