class WikiHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :wiki

  CSS_CLASS_TOUCHED = 'diff-touched'
  CSS_CLASS_ADDED = 'diff-added'
  CSS_CLASS_REMOVED = 'diff-removed'

  scope :recent, -> { order(created_at: :desc).order(id: :desc) }

  def activity
    user_word = if user.present?
      if block_given?
        yield user
      else
        "@#{user.nickname}님이"
      end
    else
      I18n.t("views.user.anonymous")
    end

    I18n.t("views.wiki.history.#{code}", default: nil, user_word: user_word)
  end

  def touched_body?
    %w(update_body update_title_and_body).include? code
  end

  def touched_title?
    %w(update_title update_title_and_body).include? code
  end

  def previous
    @previous ||= wiki.wiki_histories.recent.where('created_at < ?', self.created_at).where('id < ?', self.id).first
  end

  def has_previous?
    previous.present?
  end

  def diff_body_count
    return [0, 0] unless touched_body?

    # previous_text_body = ActionView::Base.full_sanitizer.sanitize previous.body.try(:strip) || ""
    # current_text_body = ActionView::Base.full_sanitizer.sanitize body.try(:strip) || ""

    # Diffy::Diff.new(previous_text_body, current_text_body).to_s(:html)

    grouped_diffs = node_only_diffs.group_by { |change, _| change  }
    [(grouped_diffs["+"].try(:count) || 0), (grouped_diffs["-"].try(:count) || 0)]
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

      add_node_class node, WikiHistory::CSS_CLASS_TOUCHED
    end

    added_nodes.each do |node|
      Rails.logger.debug node.inspect
      if node.element?
        add_node_class node, WikiHistory::CSS_CLASS_ADDED
      else
        new_parent = Nokogiri::XML::Element.new "span", current_doc
        new_parent['class'] = WikiHistory::CSS_CLASS_ADDED
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

      add_node_class node, WikiHistory::CSS_CLASS_TOUCHED
    end

    removed_map.each do |node|
      if node.element?
        add_node_class node, WikiHistory::CSS_CLASS_REMOVED
      else
        new_parent = Nokogiri::XML::Element.new "span", previous_doc
        new_parent['class'] = WikiHistory::CSS_CLASS_REMOVED
        node.add_next_sibling new_parent

        new_parent.add_child node
      end
    end

    @_diff_removed_body = previous_doc.to_html
  end

  def diff_body
    return unless touched_body?
    return @_diff_body if @_diff_body.present?

    diffs, current_doc, previous_doc = build_diffs

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

      add_node_class node, WikiHistory::CSS_CLASS_TOUCHED
    end

    added_nodes.each do |node|
      if node.element?
        add_node_class node, WikiHistory::CSS_CLASS_ADDED
      else
        new_parent = Nokogiri::XML::Element.new "span", current_doc
        new_parent['class'] = WikiHistory::CSS_CLASS_ADDED
        node.add_next_sibling new_parent

        new_parent.add_child node
      end
    end

    removed_map.each do |item|
      if item[:node].element?
        add_node_class item[:node], WikiHistory::CSS_CLASS_REMOVED
        item[:parent].add_child item[:node]
      else
        new_parent = Nokogiri::XML::Element.new "span", current_doc
        new_parent['class'] = WikiHistory::CSS_CLASS_REMOVED
        new_parent.add_child item[:node]

        item[:parent].add_child new_parent
      end
    end

    @_diff_body = current_doc.to_html
  end

  private

  def add_node_class node, new_class
    node['class'] = ((node['class'] || "").split(/\s+/) + [new_class]).uniq.join(" ")
  end

  def build_diffs
    current_doc = Nokogiri::HTML(body.try(:strip) || "")
    previous_doc = Nokogiri::HTML(previous.body.try(:strip) || "")
    [previous_doc.diff(current_doc, added: true, removed: true).to_a, current_doc, previous_doc]
  end

  def node_only_diffs
    return @_node_only_diffs if @_node_only_diffs.present?
    diffs, _, _ = build_diffs
    @_node_only_diffs ||= diffs.select { |_, node| (node.element? or node.text?) }
  end
end
