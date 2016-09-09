require 'test_helper'

class IssuesTest < ActionDispatch::IntegrationTest
  test '로그인 안해도 첫페이지가 잘보여요' do
    get root_path
    assert_response :success
  end

  test '만들어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).persisted?
    assert_equal 'title', assigns(:issue).title
    assert_equal Section::DEFAULT_NAME, assigns(:issue).sections.first.name
  end

  test '카테고리 안에 만들어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body', category_slug: 'category1' })

    assert assigns(:issue).persisted?
    assert_equal 'category1', assigns(:issue).category_slug
  end

  test '만든 사람이 메이커가 되어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).reload.made_by?(users(:one))
  end

  test '만든 사람은 구독 되어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).reload.watched_by?(users(:one))
  end

  test '만든 사람은 멤버가 되어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).reload.member?(users(:one))
  end

  test '같은 주소로는 못 만들어요' do
    sign_in(users(:one))

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    assert assigns(:issue).persisted?

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    refute assigns(:issue).persisted?

    host! "#{Group::GWANGJU.slug}.example.com"

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    assert assigns(:issue).persisted?

    post issues_path, issue: { title: 'title', slug: 'title', body: 'body' }
    refute assigns(:issue).persisted?
  end

  test '대소문자를 안가려요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'Title', slug: 'Title', body: 'body' })
    assert assigns(:issue).persisted?
    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:issue).persisted?
  end

  test '고쳐요' do
    sign_in(users(:maker))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x' })

    assigns(:issue).reload
    assert_equal 'title x', assigns(:issue).title
  end

  test '메이커를 넣어요' do
    sign_in(users(:maker))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', makers_nickname: users(:one).nickname })

    assigns(:issue).reload
    assert_equal users(:one), assigns(:issue).makers.first.user
  end

  test '중복된 메이커를 넣으면 알아서 넣어줘요.' do
    sign_in(users(:maker))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', makers_nickname: "#{users(:one).nickname},#{users(:one).nickname}" })

    assigns(:issue).reload
    assert_equal users(:one), assigns(:issue).makers.first.user
  end

  test '블라인드할 사용자를 넣어요' do
    sign_in(users(:maker))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', blinds_nickname: users(:one).nickname })

    assigns(:issue).reload
    assert_equal users(:one), assigns(:issue).blinds.first.user
  end

  test '중복된 블라인드를 넣으면 알아서 넣어줘요.' do
    sign_in(users(:maker))

    put issue_path(issues(:issue1), issue: { title: 'title x', body: 'body x', blinds_nickname: "#{users(:one).nickname},#{users(:one).nickname}" })

    assigns(:issue).reload
    assert_equal users(:one), assigns(:issue).blinds.first.user
  end

  test 'all이라는 이슈는 못만들어요' do
    sign_in(users(:one))

    post issues_path(issue: { title: 'all', slug: 'all', body: 'body' })

    refute assigns(:issue).persisted?
  end

  test '메이커넣기' do
    sign_in(users(:maker))
    put issue_path(issues(:issue1), issue: { makers_nickname: 'nick1' })

    assert_equal users(:one), issues(:issue1).reload.makers.first.user
  end

  test '그룹빠띠' do
    host! "#{Group::GWANGJU.slug}.example.com"
    sign_in(users(:one))

    post issues_path(issue: { title: 'title', slug: 'title', body: 'body' })

    assert assigns(:issue).persisted?
    assert_equal Group::GWANGJU, assigns(:issue).group
  end
end
