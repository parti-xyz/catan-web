module HistoryTrackable
  extend ActiveSupport::Concern

  included do
    has_many histories_attr_name, dependent: :destroy
    belongs_to last_history_attr_name, class_name: "#{self.to_s}History", foreign_key: last_history_column_name, optional: true
    has_many authors_attr_name, dependent: :destroy
    belongs_to :last_author, class_name: "User", foreign_key: :last_author_id, optional: true

    attr_accessor :continue_editing

    after_create :build_history_after_create
    after_update :build_history_after_update

    private

    def build_history!(code)
      send(self.class.authors_attr_name).find_or_create_by(user: last_author)

      histories = send(self.class.histories_attr_name)
      last_history = send(self.class.last_history_attr_name)

      ActiveRecord::Base.transaction do
        current_history = if continue_editing && histories.any? && last_history.user == last_author
          attribues_for_saving = build_attribues_for_saving(code, last_history)
          last_history.update_attributes(attribues_for_saving.merge(created_at: Time.current))
          last_history
        else
          attribues_for_saving = build_attribues_for_saving(code)
          histories.create(attribues_for_saving.merge(user: last_author))
        end

        self.update_column(self.class.last_history_column_name, current_history.id)
      end
    end

    def build_history_after_create
      code = code_after_create_for_history_trackable
      return unless code

      build_history!(code)
    end

    def build_history_after_update
      code = code_after_update_for_history_trackable
      return unless code

      build_history!(code)
    end

    def check_trivial_update_body
      return false if body_before_last_save.blank? || body.blank?

      doc1 = Nokogiri::HTML(self.body_before_last_save)
      doc2 = Nokogiri::HTML(self.body)
      diffs = doc1.diff(doc2)

      previous_text_node_diff = nil
      diffs.each do |change, node|
        if change == ' '
          previous_text_node_diff = nil
          next
        end

        return false unless node.text?

        if previous_text_node_diff.nil?
          previous_text_node_diff = [change, node.text]
          next
        end

        previous_text_node_diff_change, previous_text_node_diff_text = previous_text_node_diff

        if previous_text_node_diff_change == change
          previous_text_node_diff = [change, node.text]
          next
        end

        return false if previous_text_node_diff_text.gsub(/\s+/, '') != node.text.gsub(/\s+/, '')
      end

      true
    end

    def build_attribues_for_saving(code, last_history = nil)
      trivial_update_body = last_history&.trivial_update_body
      if trivial_update_body || last_history.blank?
        trivial_update_body = check_trivial_update_body
      end
      merged_code = merge_code_for_history_trackable(current_code: code, before_code: last_history&.code)

      result = { body: body, code: merged_code, trivial_update_body: trivial_update_body }

      if respond_to?(:title_for_history_trackable)
        result[:title] = title_for_history_trackable
      end

      result
    end
  end

  class_methods do
    def histories_attr_name
      "#{self.to_s.underscore}_histories".to_sym
    end

    def last_history_attr_name
      "last_#{self.to_s.underscore}_history".to_sym
    end

    def last_history_column_name
      "#{last_history_attr_name}_id".to_sym
    end

    def authors_attr_name
      "#{self.to_s.underscore}_authors".to_sym
    end
  end
end