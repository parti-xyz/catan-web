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

  def survey_card_dom_class(post)
    dom_id(post.survey)
  end

  def survey_card_dom_selector(post)
    ".sruvey-card.#{survey_card_dom_class(post)}"
  end

  def post_pin_buttons_dom_class(post)
    "#{dom_id(post)}-pin-buttons"
  end

  def post_pin_buttons_dom_selector(post)
    ".#{post_pin_buttons_dom_class(post)}"
  end
end
