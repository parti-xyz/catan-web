require 'test_helper'

class HashtagsTest < ActionDispatch::IntegrationTest
  test '로그인 안해도 해시태그 페이지가 잘 보여요' do
    get slug_issue_hashtags_path(slug: 'issue2', hashtag: 'test')
    assert_response :success
  end
end
