require 'test_helper'

class CampaignsTest < ActionDispatch::IntegrationTest
  test '만들어요' do
    sign_in(users(:admin))

    post campaigns_path(campaign: { title: 'title', slug: 'title', body: 'body', issue_slugs: "issue2, issue4" })

    assert assigns(:campaign).persisted?
    assert_equal 'title', assigns(:campaign).title
    assert assigns(:campaign).issues.exists?(issues(:issue2).id)
    assert assigns(:campaign).issues.exists?(issues(:issue4).id)
  end

  test '같은 이름으로는 못 만들어요' do
    sign_in(users(:admin))

    post campaigns_path(campaign: { title: 'title', slug: 'title', body: 'body' })
    assert assigns(:campaign).persisted?
    post campaigns_path(campaign: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:campaign).persisted?
  end

  test '대소문자를 안가려요' do
    sign_in(users(:admin))

    post campaigns_path(campaign: { title: 'Title', slug: 'Title', body: 'body' })
    assert assigns(:campaign).persisted?
    post campaigns_path(campaign: { title: 'title', slug: 'title', body: 'body' })
    refute assigns(:campaign).persisted?
  end

  test '고쳐요' do
    sign_in(users(:admin))

    put campaign_path(campaigns(:campaign1), campaign: { title: 'title x', body: 'body x' })

    assigns(:campaign).reload
    assert_equal 'title x', assigns(:campaign).title
  end

  test 'all이라는 그룹은 못만들어요' do
    sign_in(users(:admin))

    post campaigns_path(campaign: { title: 'all', slug: 'all', body: 'body' })

    refute assigns(:campaign).persisted?
  end
end
