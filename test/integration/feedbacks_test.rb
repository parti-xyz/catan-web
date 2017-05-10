require 'test_helper'

class FeedbacksTest < ActionDispatch::IntegrationTest
  test '하나만 투표를 할 수 있어요' do
    refute surveys(:survey1).multiple_select?

    sign_in users(:two)
    post feedbacks_path(post_id: surveys(:survey1).post.id, option_id: surveys(:survey1).options.first, selected: 'true', format: :js)
    assert surveys(:survey1).feedbacked? users(:two)
    assert surveys(:survey1).options.first.selected? users(:two)
    refute surveys(:survey1).options.second.selected? users(:two)

    post feedbacks_path(post_id: surveys(:survey1).post.id, option_id: surveys(:survey1).options.second, selected: 'true', format: :js)
    assert surveys(:survey1).feedbacked? users(:two)
    refute surveys(:survey1).options.first.selected? users(:two)
    assert surveys(:survey1).options.second.selected? users(:two)

    post feedbacks_path(post_id: surveys(:survey1).post.id, option_id: surveys(:survey1).options.second, selected: 'false', format: :js)
    refute surveys(:survey1).feedbacked? users(:two)
    refute surveys(:survey1).options.first.selected? users(:two)
    refute surveys(:survey1).options.second.selected? users(:two)
  end

  test '여러개 투표를 할 수 있어요' do
    surveys(:survey1).update_attributes(multiple_select: true)

    sign_in users(:two)
    post feedbacks_path(post_id: surveys(:survey1).post.id, option_id: surveys(:survey1).options.first, selected: 'true', format: :js)
    assert surveys(:survey1).feedbacked? users(:two)
    assert surveys(:survey1).options.first.selected? users(:two)
    refute surveys(:survey1).options.second.selected? users(:two)

    post feedbacks_path(post_id: surveys(:survey1).post.id, option_id: surveys(:survey1).options.second, selected: 'true', format: :js)
    assert surveys(:survey1).feedbacked? users(:two)
    assert surveys(:survey1).options.first.selected? users(:two)
    assert surveys(:survey1).options.second.selected? users(:two)

    post feedbacks_path(post_id: surveys(:survey1).post.id, option_id: surveys(:survey1).options.second, selected: 'false', format: :js)
    assert surveys(:survey1).feedbacked? users(:two)
    assert surveys(:survey1).options.first.selected? users(:two)
    refute surveys(:survey1).options.second.selected? users(:two)

    post feedbacks_path(post_id: surveys(:survey1).post.id, option_id: surveys(:survey1).options.first, selected: 'false', format: :js)
    refute surveys(:survey1).feedbacked? users(:two)
    refute surveys(:survey1).options.first.selected? users(:two)
    refute surveys(:survey1).options.second.selected? users(:two)
  end
end
