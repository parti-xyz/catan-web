module DomHelper
  def new_comment_form_dom_id(post, comment)
    [dom_id(post), ("-#{dom_id(comment)}" if comment.present?), "--new-comment"].compact.join('')
  end

  def new_comment_form_dom_selector(post, comment)
    "form##{new_comment_form_dom_id(post, comment)}"
  end

  def new_comment_form_body_input_dom_id(post, comment)
    [dom_id(post), ("-#{dom_id(comment)}" if comment.present?), "--new-comment--body-input"].compact.join('')
  end

  def new_comment_form_body_input_dom_selector(post, comment = nil)
    "#{new_comment_form_dom_selector(post, comment)} ##{new_comment_form_body_input_dom_id(post, comment)}"
  end

  def new_comment_form_submit_dom_selector(post, comment)
    "#{new_comment_form_dom_selector(post, comment)} input[type=submit]"
  end

  def comments_count_dom_id(post)
    "#{dom_id(post)}-comments-count"
  end

  def comments_count_dom_selector(post)
    "##{comments_count_dom_id(post)}"
  end

  def comments_threads_dom_id(post)
    "#{dom_id(post)}-comments-threads"
  end

  def comments_threads_dom_selector(post)
    "##{comments_threads_dom_id(post)}"
  end

  def comments_children_dom_id(comment)
    "#{dom_id(comment.post)}-#{dom_id(comment)}-comments-children"
  end

  def comments_children_dom_selector(comment)
    "##{comments_children_dom_id(comment)}"
  end

  def comment_line_anchor_dom_id(comment)
    "anchor_#{dom_id(comment)}"
  end

  def comment_line_dom_id(comment)
    dom_id(comment)
  end

  def comment_line_dom_selector(comment)
    ".#{dom_id(comment)}"
  end

  def comments_more_button_dom_id(post)
    "#{dom_id(post)}-comments-more-btn"
  end

  def comments_more_button_dom_selector(post)
    "##{comments_more_button_dom_id(post)}"
  end

  def comments_more_label_dom_id(post)
    "#{dom_id(post)}-comments-more-label"
  end

  def comments_more_label_dom_selector(post)
    "##{comments_more_label_dom_id(post)}"
  end

  def comments_more_children_button_dom_id(comment)
    "#{dom_id(comment.post)}-#{dom_id(comment)}-comments-more-children-btn"
  end

  def comments_more_children_button_dom_selector(comment)
    "##{comments_more_children_button_dom_id(comment)}"
  end

  def comments_more_children_label_dom_id(comment)
    "#{dom_id(comment.post)}-#{dom_id(comment)}-comments-more-children-label"
  end

  def comments_more_children_label_dom_selector(comment)
    "##{comments_more_children_label_dom_id(comment)}"
  end

  def removable_with_post_dom_class(post)
    "removable-with-#{dom_id(post)}"
  end

  def removable_with_post_dom_selector(post)
    ".#{removable_with_post_dom_class(post)}"
  end

  def post_votings_dom_class(post)
    "#{dom_id(post)}-vote"
  end

  def post_votings_dom_selector(post)
    ".#{post_votings_dom_class(post)}"
  end

  def post_folder_dom_class(post)
    "#{dom_id(post)}-folder"
  end

  def post_folder_dom_selector(post)
    ".#{post_folder_dom_class(post)}"
  end

  def post_folder_wrapper_dom_class(post)
    "#{dom_id(post)}-folder-wrapper"
  end

  def post_folder_wrapper_dom_selector(post)
    ".#{post_folder_wrapper_dom_class(post)}"
  end

  def folder_dom_class(folder)
    "folder-#{folder.id}"
  end

  def folder_dom_selector(folder)
    ".#{folder_dom_class(folder)}"
  end

  def survey_options_dom_class(post)
    dom_id(post.survey)
  end

  def survey_options_dom_selector(post)
    ".survey-options.#{survey_options_dom_class(post)}"
  end

  def event_dom_class(post)
    "post-#{dom_id(post.event)}"
  end

  def event_dom_selector(post)
    ".#{event_dom_class(post)}"
  end

  def switchable_post_pin_buttons_dom_class(post)
    "#{dom_id(post)}-switchable-pin-buttons"
  end

  def switchable_post_pin_buttons_dom_selector(post)
    ".#{switchable_post_pin_buttons_dom_class(post)}"
  end

  def switchable_post_main_wiki_buttons_dom_class(post)
    "#{dom_id(post)}-switchable-front-wiki-buttons"
  end

  def switchable_post_main_wiki_buttons_dom_selector(post)
    ".#{switchable_post_main_wiki_buttons_dom_class(post)}"
  end

  def user_chevron_dom_id(user)
    "#{dom_id(user)}-dropdown"
  end

  def pinned_post_dom_selector(post)
    ".#{pinned_post_dom_class(post)}"
  end

  def pinned_post_dom_class(post)
    "#{dom_id(post)}--list-pinned"
  end

  def bookmarked_post_dom_selector(post)
    ".#{bookmarked_post_dom_class(post)}"
  end

  def bookmarked_post_dom_class(post)
    "#{dom_id(post)}--list-bookmarked"
  end

  def bookmark_button_post_dom_selector(post)
    ".#{bookmark_button_post_dom_class(post)}"
  end

  def bookmark_button_post_dom_class(post)
    "#{dom_id(post)}--bookmark-button"
  end

  def bookmark_tags_post_dom_selector(post)
    ".#{bookmark_tags_post_dom_class(post)}"
  end

  def bookmark_tags_post_dom_class(post)
    "#{dom_id(post)}--bookmark-tags"
  end

  def behold_post_dom_selector(post)
    ".#{behold_post_dom_class(post)}"
  end

  def behold_post_dom_class(post)
    "#{dom_id(post)}--behold"
  end

  def behold_button_dom_selector(post)
    ".#{behold_button_dom_class(post)}"
  end

  def behold_button_dom_class(post)
    "#{dom_id(post)}-behold-button"
  end

  def unbehold_button_dom_selector(post)
    ".#{unbehold_button_dom_class(post)}"
  end

  def unbehold_button_dom_class(post)
    "#{dom_id(post)}-unbehold-button"
  end

  def folded_post_dom_class(post)
    "#{dom_id(post)}--folded"
  end

  def folded_post_dom_selector(post)
    ".#{folded_post_dom_class(post)}"
  end

  def post_decision_dom_class(post)
    "#{dom_id(post)}--edit-decision"
  end

  def post_decision_dom_selector(post)
    ".#{post_decision_dom_class(post)}"
  end

  def issue_line_category_dom_selector(issue)
    ".#{issue_line_category_dom_class(issue)}"
  end

  def issue_line_category_dom_class(issue)
    "#{dom_id(issue)}-js-issue-line-category"
  end

  def group_category_issue_list_dom_selector(category)
    ".#{group_category_issue_list_dom_class(category)}"
  end

  def group_category_issue_list_dom_class(category)
    "#{category.present? ? dom_id(category) : 'category-nil'}-js-category-issue-list"
  end

  def splited_post_dom_id
    "__splited_post_dom"
  end

  def splited_left_dom_id
    "__splited_left_dom"
  end

  def splited_right_dom_id
    "__splited_right_dom"
  end
end
