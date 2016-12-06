require 'test_helper'

class MessagesTest < ActionDispatch::IntegrationTest
  test '내가 댓글단 게시글의 댓글에서 나를 멘션할 경우에는 알림이 한 번만 옵니다' do
    # post_talk3 one이쓰고 two가 댓글달았다
    sign_in(users(:one))

    previous_messages_count = users(:two).messages.count
    # talk3에 one이 two를 멘션하는 댓글을 쓴다.
    post post_comments_path(post_id: posts(:post_talk3).id, comment: { body: 'body @nick2' }), format: :js

    # 이전의 알람갯수보다 이후 알람갯수가 +1되어야한다.
    assert_equal previous_messages_count + 1, users(:two).reload.messages.count
  end

  test '내가 멘션 안된 댓글이 수정될 때 내가 멘션되면 알림이 오지만, 내가 멘션 된 댓글이 수정될 때 다른 사람이 추가로 멘션이 될때는 알림이 오지 않습니다' do
    sign_in(users(:one))

    post post_comments_path(post_id: posts(:post_talk3).id, comment: { body: 'body @nick3' }), format: :js

    nick2_previous_messages_count = users(:two).reload.messages.count
    nick3_previous_messages_count = users(:three).reload.messages.count

    put comment_path(assigns(:comment), comment: { body: 'body @nick3 @nick2' }), format: :js

    assert_equal nick2_previous_messages_count + 1, users(:two).reload.messages.count
    assert_equal nick3_previous_messages_count, users(:three).reload.messages.count
  end
end
