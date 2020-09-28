module Historyable
  extend ActiveSupport::Concern

  CSS_CLASS_TOUCHED = 'diff-touched'
  CSS_CLASS_ADDED = 'diff-added'
  CSS_CLASS_REMOVED = 'diff-removed'

  included do
    before_save :build_diff_body_count
    scope :recent, -> { order(created_at: :desc).order(id: :desc) }

    def previous
      @previous ||= if self.persisted?
        previouse = self.sibling_histories.recent.where('created_at < ?', self.created_at).where('id < ?', self.id).first
        previouse = previouse.significant if self.respond_to?(:significant)

        previouse
      else
        self.sibling_histories.last
      end
    end

    def has_previous?
      previous.present?
    end

    def afterwhile
      @next ||= if self.persisted?
        afterwhile = self.sibling_histories.recent.where('created_at > ?', self.created_at).where('id > ?', self.id).last
        afterwhile = afterwhile.significant if self.respond_to?(:significant)

        afterwhile
      else
        self.sibling_histories.first
      end
    end

    def has_afterwhile?
      afterwhile.present?
    end

    def build_diff_body_count
      unless touched_body?
        self.diff_body_adds_count = 0
        self.diff_body_removes_count = 0
      end
      grouped_diffs = node_only_diffs.group_by { |change, _| change  }
      self.diff_body_adds_count = (grouped_diffs["+"].try(:count) || 0)
      self.diff_body_removes_count = (grouped_diffs["-"].try(:count) || 0)
    end

    def diff_body_count
      [diff_body_adds_count, diff_body_removes_count]
    end

    def diff_added_body
      return unless touched_body?
      return @_diff_added_body if @_diff_added_body.present?

      diffs, current_doc, _ = build_diffs
      touched_nodes = []
      added_nodes = []

      diffs.each do |change, node|
        next unless change == '+'

        if !node.element? and !node.text?
          touched_nodes << node.parent
          next
        end

        added_nodes << node
      end

      touched_nodes.each do |node|
        if !node.element? and !node.text?
          Rails.logger.debug "Unknown Diff : #{node.inspect}"
          next
        end

        add_node_class node, Historyable::CSS_CLASS_TOUCHED
      end

      added_nodes.each do |node|
        Rails.logger.debug node.inspect
        if node.element?
          add_node_class node, Historyable::CSS_CLASS_ADDED
        else
          new_parent = Nokogiri::XML::Element.new "span", current_doc
          new_parent['class'] = Historyable::CSS_CLASS_ADDED
          node.add_next_sibling new_parent

          new_parent.add_child node
        end
      end

      @_diff_added_body = current_doc.to_html
    end

    def diff_removed_body
      return unless touched_body?
      return @_diff_removed_body if @_diff_removed_body.present?

      diffs, _, previous_doc = build_diffs
      touched_nodes = []
      removed_map = []

      diffs.each do |change, node|
        next unless change == '-'

        if !node.element? and !node.text?
          touched_nodes << node.parent
          next
        end

        removed_map << node
      end

      touched_nodes.each do |node|
        if !node.element? and !node.text?
          Rails.logger.debug "Unknown Diff : #{node.inspect}"
          next
        end

        add_node_class node, Historyable::CSS_CLASS_TOUCHED
      end

      removed_map.each do |node|
        if node.element?
          add_node_class node, Historyable::CSS_CLASS_REMOVED
        else
          new_parent = Nokogiri::XML::Element.new "span", previous_doc
          new_parent['class'] = Historyable::CSS_CLASS_REMOVED
          node.add_next_sibling new_parent

          new_parent.add_child node
        end
      end

      @_diff_removed_body = previous_doc.to_html
    end

    def diff_body(temp_body = nil)
      return if !touched_body? and temp_body.blank?
      return @_diff_body if @_diff_body.present? and temp_body.blank?

      diffs, current_doc, previous_doc = build_diffs(diffable_body, temp_body)

      touched_nodes = []
      added_nodes = []
      removed_map = []

      diffs.each do |change, node|
        if change == '+'
          if !node.element? and !node.text?
            touched_nodes << node.parent
            next
          end

          added_nodes << node
        elsif change == '-'
          if !node.element? and !node.text?
            touched_nodes << node.parent
            next
          end

          removed_map << { parent: current_doc.at(node.parent.path), node: node}
        end
      end


      touched_nodes.each do |node|
        if !node.element? and !node.text?
          Rails.logger.debug "Unknown Diff : #{node.inspect}"
          next
        end

        add_node_class node, Historyable::CSS_CLASS_TOUCHED
      end

      added_nodes.each do |node|
        if node.element?
          add_node_class node, Historyable::CSS_CLASS_ADDED
        else
          new_parent = Nokogiri::XML::Element.new "span", current_doc
          new_parent['class'] = Historyable::CSS_CLASS_ADDED
          node.add_next_sibling new_parent

          new_parent.add_child node
          wrap_with(new_parent, Historyable::CSS_CLASS_ADDED)
        end
      end

      removed_map.each do |item|
        if item[:node].element?
          add_node_class item[:node], Historyable::CSS_CLASS_REMOVED
          item[:parent].add_child item[:node]

          wrap_with(item[:node], Historyable::CSS_CLASS_REMOVED)
        else
          new_parent = Nokogiri::XML::Element.new "span", current_doc
          new_parent['class'] = Historyable::CSS_CLASS_REMOVED
          new_parent.add_child item[:node]
          item[:parent].add_child new_parent

          wrap_with(new_parent, Historyable::CSS_CLASS_REMOVED)
        end
      end

      @_diff_body = current_doc.to_html
    end

    private

    def add_node_class node, new_class
      node['class'] = ((node['class'] || "").split(/\s+/) + [new_class]).uniq.join(" ")
      wrap_with(node, new_class)
    end

    def build_diffs(current_diffable_body = nil, previous_diffable_body = nil)
      current_diffable_body = diffable_body.try(:strip) unless current_diffable_body.present?
      previous_diffable_body = previous.try(:diffable_body).try(:strip) unless previous_diffable_body.present?

      current_doc = Nokogiri::HTML(current_diffable_body || "")
      previous_doc = Nokogiri::HTML(previous_diffable_body || "")
      [previous_doc.diff(current_doc, added: true, removed: true).to_a, current_doc, previous_doc]
    end

    def node_only_diffs
      return @_node_only_diffs if @_node_only_diffs.present?
      diffs, _, _ = build_diffs
      @_node_only_diffs ||= diffs.select { |_, node| (node.element? or node.text?) }
    end

    def as_tag class_name
      class_name.split('-').collect(&:capitalize).join
    end

    def wrap_with node, class_name
      node.wrap("<#{as_tag(class_name)} />")
    end
  end
end
