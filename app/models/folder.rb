class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue
  has_many :posts, dependent: :nullify

  scope :sort_by_name, -> { order("if(ascii(substring(title, 1)) < 128, 1, 0)").order('title') }

  def self.tryable?(issue)
    return false if issue.blank?
    issue.group.slug == 'union'
  end
end
