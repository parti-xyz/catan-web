class Folder < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue
  has_many :posts, dependent: :nullify
  belongs_to :parent, class_name: Folder, foreign_key: :parent_id, counter_cache: :children_count
  has_many :children, class_name: Folder, foreign_key: :parent_id

  scope :only_parent, -> { where(parent_id: nil) }
  scope :sort_by_name, -> { order("if(ascii(substring(title, 1)) < 128, 1, 0)").order('title') }

  validates :title, uniqueness: {scope: [:issue_id]}

  def full_title
    result = ""
    result += "#{parent.full_title} - " if parent.present?
    "#{result}#{title}"
  end

  def self.compare_by_name(folder)
    [(folder.title[0].match(/\p{Hangul}/).present? ? 0 : 1), folder.title]
  end

  def self.threaded(folders)
    result = folders.to_a.group_by { |folder| folder.parent_or_self }
    result.each do |item|
      item[1].reject! { |folder| folder.parent.blank? }
      item[1].sort_by! { |folder| Folder.compare_by_name(folder) }
    end
    result.to_a.sort_by! { |folder, _| Folder.compare_by_name(folder) }
  end

  def parent_or_self
    parent || self
  end
end
