require 'test_helper'

class MessagesTest < ActionDispatch::IntegrationTest
  test '내가 댓글단 게시글의 댓글에서 나를 멘션할 경우에는 알림이 한 번만 옵니다' do
    # post_talk3 one이쓰고 two가 댓글달았다
    sign_in(users(:one))

    previous_messages_count = users(:two).messages.count
    # talk3에 one이 two를 멘션하는 댓글을 쓴다.

    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk3).id, comment: { body: 'body @nick2' }), format: :js
    end

    # 이전의 알람갯수보다 이후 알람갯수가 +1되어야한다.
    assert_equal previous_messages_count + 1, users(:two).reload.messages.count
  end

  test '내 게시글의 댓글에서 나를 멘션 안했다가 다시 멘션한 경우에는 알림이 한 번만 옵니다' do
    assert users(:one), posts(:post_talk3).user
    # post_talk3 one이쓰고 two가 댓글달았다
    sign_in(users(:two))

    previous_messages_count = users(:one).messages.count
    # talk3에 one이 two를 멘션하는 댓글을 쓴다.

    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk3).id, comment: { body: "body" }), format: :js
      patch comment_path(assigns(:comment).id, comment: { body: "body @#{users(:one).nickname}" }), format: :js
    end

    # 이전의 알람갯수보다 이후 알람갯수가 +1되어야한다.
    assert_equal previous_messages_count + 1, users(:one).reload.messages.count
  end

  test '내가 멘션 안된 댓글이 수정될 때 내가 멘션되면 알림이 오지만, 내가 멘션 된 댓글이 수정될 때 다른 사람이 추가로 멘션이 될때는 알림이 오지 않습니다' do
    sign_in(users(:one))
    Sidekiq::Testing.inline! do
      post post_comments_path(post_id: posts(:post_talk3).id, comment: { body: 'body @nick3' }), format: :js
    end

    nick4_previous_messages_count = users(:four).reload.messages.count
    nick3_previous_messages_count = users(:three).reload.messages.count

    Sidekiq::Testing.inline! do
      put comment_path(assigns(:comment), comment: { body: 'body @nick3 @nick4' }), format: :js
    end
    assert_equal nick4_previous_messages_count + 1, users(:four).reload.messages.count
    assert_equal nick3_previous_messages_count, users(:three).reload.messages.count
  end

  test '삭제된 빠띠의 탈퇴시킨 사람의 메시지가 지워집니다' do
    assert issues(:issue1).member? users(:one)
    sign_in(users(:admin))
    delete ban_issue_members_path(issue_id: issues(:issue1).id, user_id: users(:one).id, format: :js)

    issues(:issue1).posts.destroy_all
    issues(:issue1).members.destroy_all

    Sidekiq::Testing.inline! do
      delete issue_path(issues(:issue1))
    end
    assert assigns(:issue).reload.paranoia_destroyed?

    get messages_path(user: users(:one).nickname)
    assert_response :success
  end

  test '삭제된 빠띠의 멤버 요청 관련한 메시지가 지워집니다' do
    refute issues(:private_issue).member_requested? users(:two)

    # 가입요청
    sign_in(users(:two))
    post issue_member_requests_path(issue_id: issues(:private_issue).id)
    member_request = assigns(:member_request)
    assert issues(:private_issue).member_requested? users(:two)

    sign_out

    # 거절
    sign_in(users(:admin))
    delete reject_issue_member_requests_path(issue_id: issues(:private_issue).id), { user_id: users(:two).id  }
    assert member_request, users(:two).reload.messages.last.messagable

    # 빠띠 삭제
    issues(:private_issue).posts.destroy_all
    issues(:private_issue).members.destroy_all
    Sidekiq::Testing.inline! do
      delete issue_path(issues(:private_issue))
    end
    assert assigns(:issue).reload.paranoia_destroyed?

    get messages_path(user: users(:two).nickname)
    assert_response :success
  end

  test '옵션이 삭제되면 해당 메시지도 삭제됩니다' do
    # 설문 만들기
    sign_in(users(:one))
    post posts_path(post: { body: 'body', has_survey: 'true', issue_id: issues(:issue2).id,
      survey_attributes: { title: 'survey_title', duration: 3 } })

    post = assigns(:post)
    sign_out

    # 옵션 만들기
    sign_in(users(:recipient))
    post options_path(format: :js, option: { body: 'body', survey_id: post.survey.id })

    option = assigns(:option)
    assert users(:one).reload.messages.exists?(messagable: option)

    # 옵션 지우기
    delete option_path(option, format: :js)

    refute users(:one).reload.messages.exists?(messagable: option)
  end

  test '설문이 있는 글이 삭제되면 해당 메시지도 삭제됩니다' do
    # 설문 만들기
    sign_in(users(:one))
    post posts_path(post: { body: 'body', has_survey: 'true', issue_id: issues(:issue2).id,
      survey_attributes: { title: 'survey_title', duration: 3 } })

    post = assigns(:post)
    survey = post.survey
    sign_out

    # 옵션 만들기
    sign_in(users(:recipient))
    post options_path(format: :js, option: { body: 'body', survey_id: post.survey.id })

    option = assigns(:option)
    assert users(:one).reload.messages.exists?(messagable: option)
    sign_out

    # 설문 지우기
    sign_in(users(:one))
    delete post_path(post)

    refute users(:one).reload.messages.exists?(messagable: option)
  end
end
