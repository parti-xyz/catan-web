module DomHelper
  def new_comment_form_dom_id(post)
    "#{dom_id(post)}--new-comment"
  end

  def new_comment_form_dom_selector(post)
    "form##{new_comment_form_dom_id(post)}"
  end

  def new_comment_form_body_input_dom_id(post)
    "#{dom_id(post)}--new-comment--body-input"
  end

  def new_comment_form_body_input_dom_selector(post)
    "#{new_comment_form_dom_selector(post)} ##{new_comment_form_body_input_dom_id(post)}"
  end

  def new_comment_form_submit_dom_selector(post)
    "#{new_comment_form_dom_selector(post)} input[type=submit]"
  end

  def comments_count_dom_id(post)
    "#{dom_id(post)}-comments-count"
  end

  def comments_count_dom_selector(post)
    "##{comments_count_dom_id(post)}"
  end

  def comments_more_dom_id(post)
    "#{dom_id(post)}-comments-more"
  end

  def comments_more_dom_selector(post)
    "##{comments_more_dom_id(post)}"
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

  def survey_options_dom_class(post)
    dom_id(post.survey)
  end

  def survey_options_dom_selector(post)
    ".survey-options.#{survey_options_dom_class(post)}"
  end

  def switchable_post_pin_buttons_dom_class(post)
    "#{dom_id(post)}-switchable-pin-buttons"
  end

  def switchable_post_pin_buttons_dom_selector(post)
    ".#{switchable_post_pin_buttons_dom_class(post)}"
  end

  def post_pin_button_dom_class(post)
    "#{dom_id(post)}-pin-button"
  end

  def post_pin_button_dom_selector(post)
    ".#{post_pin_button_dom_class(post)}"
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

  def read_button_dom_selector(post)
    ".#{read_button_dom_class(post)}"
  end

  def read_button_dom_class(post)
    "#{dom_id(post)}-read-button"
  end

  def issue_line_bookmark_dom_selector(issue)
    ".#{issue_line_bookmark_dom_class(issue)}"
  end

  def issue_line_bookmark_dom_class(issue)
    "#{dom_id(issue)}-js-issue-line-bookmark-btn"
  end
end
