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

  attr_accessor :cached_children

  def full_title
    result = ""
    result += "#{parent.full_title} - " if parent.present?
    "#{result}#{title}"
  end

  def self.compare_keys(folder)
    [folder.folder_seq, (folder.title[0].match(/\p{Hangul}/).present? ? 0 : 1), folder.title]
  end

  def self.threaded(folders)
    folders_array = folders.to_a

    folders_index = Hash[folders_array.map { |folder| [folder.id, folder] }]
    folders.each do |folder|
      folder.cached_children = []
    end
    result = folders_array.group_by { |folder| folder.parent }

    root_folders = nil
    result.each do |parent, children|
      children.sort_by! { |folder| Folder.compare_keys(folder) }
      if(parent == nil)
        root_folders = children
      else
        if folders_index.fetch(parent.id).present?
          folders_index.fetch(parent.id).cached_children = children
        end
      end
    end
    root_folders
  end

  def smart_children
    if self.cached_children.nil?
      self.children
    else
      self.cached_children
    end
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
end
