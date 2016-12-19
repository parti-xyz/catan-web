module CommentDomHelper
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
end
