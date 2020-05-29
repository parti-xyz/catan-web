class Folder < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :issue
  has_many :posts, dependent: :nullify
  belongs_to :parent, class_name: "Folder", foreign_key: :parent_id, counter_cache: :children_count, optional: true
  has_many :children, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy

  scope :only_top, -> { where(parent_id: nil) }
  scope :sort_by_default, -> { order(folder_seq: :asc).order(Arel.sql("if(ascii(substring(title, 1)) < 128, 1, 0)")).order('title').order(id: :asc) }

  validate :check_parent
  validate :check_sibilings

  ROOT_ID = 0

  def full_title
    result = ""
    result += "#{parent.full_title} - " if parent.present?
    "#{result}#{title}"
  end

  def self.compare_keys(folder)
    [folder.folder_seq, (folder.title[0].match(/\p{Hangul}/).present? ? 0 : 1), folder.title]
  end

  def self.threaded(folders)
    folders_array = folders.to_a.compact

    folders_index = Hash[folders_array.map { |folder| [folder.id, folder] }]

    root_folders = []
    folders_array.group_by { |folder| folder.parent_id }.each do |parent_id, children|
      children.sort_by! { |folder| Folder.compare_keys(folder) }
      if parent_id.blank?
        root_folders += children
      else
        parent_folder = folders_index.fetch(parent_id, nil)
        if parent_folder.present?
          children_association = parent_folder.association(:children)
          children_association.target = Folder.array_sort_by_default(children)
        end
      end
    end

    folders_array.each do |folder|
      parent_association = folder.association(:parent)
      parent_association.target = folders_index.fetch(folder.parent_id, nil)
      parent_association.loaded!

      children_association = folder.association(:children)
      children_association.loaded!
    end

    root_folders
  end

  def self.array_sort_by_default(folders)
    folders&.sort_by{ |child| [child.folder_seq, (child.title.codepoints[0] < 128 ? 1 : 0), child.title, child.id] }
  end

  def smart_parent

  end

  def parent_or_self
    parent || self
  end

  def safe_parent_id
    Folder.safe_id(parent.try(:id))
  end

  def siblings
    if parent.blank?
      self.issue.top_folders
    else
      self.parent.children
    end
  end

  def ancestors
    return [] if self.parent.nil?
    self.parent.ancestors << self.parent
  end

  def ancestors_and_self
    self.ancestors << self
  end

  def movable_to?(target_folder)
    (self.id != target_folder.id) and (self.safe_parent_id != target_folder.id)
  end

  def self.safe_id(id)
    id.try(:to_i).presence || ROOT_ID
  end

  def self.movable_safe_folder_id_to?(target_safe_id, subject)
    return false if subject.blank? or target_safe_id.blank?

    case subject
    when Folder
      return false if subject.id == target_safe_id
      return false if subject.parent_id == target_safe_id
      if target_safe_id != Folder::ROOT_ID
        target = Folder.find_by(id: target_safe_id)
        return false if target.blank?
        return false if target.ancestors.include?(subject)
      end
    when Post
      return false if target_safe_id == Folder::ROOT_ID
      return false if subject.folder_id == target_safe_id
    end

    return true
  end

  def check_parent
    if self.id.present? and self.id == self.parent_id
      errors.add(:slug, I18n.t('errors.messages.unknown_bad_parent_folder'))
    end

    if self.id.present?
      current_parent = self.parent
      while current_parent != nil
        if current_parent == self.id
          errors.add(:slug, I18n.t('errors.messages.unknown_bad_parent_folder'))
          return
        end
        current_parent = current_parent.parent
      end
    end
  end

  def check_sibilings
    if self.siblings.where.not(id: self.id).map(&:title).include?(self.title)
      errors.add(:slug, I18n.t('activerecord.errors.models.folder.attributes.title.taken'))
      return
    end
  end
end
