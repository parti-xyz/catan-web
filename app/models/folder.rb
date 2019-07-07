class Folder < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :issue
  has_many :posts, dependent: :nullify
  belongs_to :parent, class_name: "Folder", foreign_key: :parent_id, counter_cache: :children_count, optional: true
  has_many :children, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy

  scope :only_parent, -> { where(parent_id: nil) }
  scope :sort_by_name, -> { order(Arel.sql("if(ascii(substring(title, 1)) < 128, 1, 0)")).order('title') }
  scope :sort_by_folder_seq, -> { order(folder_seq: :asc) }

  validates :title, uniqueness: {scope: [:issue_id]}
  validate :check_parent_id

  def full_title
    result = ""
    result += "#{parent.full_title} - " if parent.present?
    "#{result}#{title}"
  end

  def self.compare_keys(folder)
    [folder.folder_seq, (folder.title[0].match(/\p{Hangul}/).present? ? 0 : 1), folder.title]
  end

  def self.threaded(folders)
    result = folders.to_a.group_by { |folder| folder.parent_or_self }
    result.each do |item|
      item[1].reject! { |folder| folder.parent.blank? }
      item[1].sort_by! { |folder| Folder.compare_keys(folder) }
    end
    result.to_a.sort_by! { |folder, _| Folder.compare_keys(folder) }
  end

  def parent_or_self
    parent || self
  end

  def siblings
    if parent.blank?
      self.issue.folders.only_parent
    else
      self.parent.children
    end
  end

  def check_parent_id
    if parent_id.present? and children.any?
      errors.add(:parent_id, I18n.t('errors.messages.folders.too_deep'))
    end
  end
end
