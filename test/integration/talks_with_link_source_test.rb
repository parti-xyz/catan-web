require 'test_helper'

class TalksWithLinkSourceTest < ActionDispatch::IntegrationTest
  def stub_crawl(link = nil)
    stub =  (link.present? ? OpenGraph.expects(:new).with(link) : OpenGraph.stubs(:new))
    stub.returns(OpenStruct.new(title: 'page title', description: 'page body', url: (link || 'http://stub.xx')))
    Sidekiq::Testing.inline! do
      yield
    end
  end

  test '만들어요' do
    stub_crawl do
      sign_in(users(:one))

      post talks_path, talk: { issue_id: issues(:issue2).id, body: 'body', section_id: sections(:section2).id, reference_attributes: { url: 'http://link.xx' }, reference_type: 'LinkSource' }
      assert assigns(:talk).persisted?
      assigns(:talk).reload
      assert_equal 'page title', assigns(:talk).reference_title
      assert_equal 'page body', assigns(:talk).reference_body
      assert_equal 'body', assigns(:talk).body
      assert_equal users(:one), assigns(:talk).user
      assert_equal LinkSource.find_by(url: 'http://stub.xx'), assigns(:talk).reference

      assert assigns(:talk).comments.empty?
    end
  end

  test '같은 링크로 여러 개의 논의를 만들 수 있어요' do
    stub_crawl do
      sign_in(users(:one))

      talk3_link = talks(:talk3).reference.url
      post talks_path, talk: { issue_id: issues(:issue2).id, body: 'body', section_id: sections(:section2).id, reference_attributes: { url: talk3_link }, reference_type: 'LinkSource' }
      assert assigns(:talk).persisted?
      assigns(:talk).reload

      assert_equal 'page title', assigns(:talk).reference_title
      assert_equal 'page body', assigns(:talk).reference_body
      assert_equal 'body', assigns(:talk).body
      assert_equal users(:one), assigns(:talk).user
      assert_equal LinkSource.find_by(url: 'http://stub.xx'), assigns(:talk).reference
      assert_equal issues(:issue2).title, assigns(:talk).issue.title

      assert assigns(:talk).comments.empty?
    end
  end

  test '고쳐요' do
    stub_crawl 'http://link.xx' do
      sign_in(users(:one))

      put talk_path(talks(:talk1)), talk: { body: 'body', issue_id: issues(:issue1).id, reference_attributes: { url: 'http://link.xx'}, reference_type: 'LinkSource' }

      refute assigns(:talk).errors.any?
      assigns(:talk).reload
      assert_equal 'page title', assigns(:talk).reference_title
      assert_equal 'page body', assigns(:talk).reference_body
      assert_equal 'body', assigns(:talk).body
      assert_equal users(:one), assigns(:talk).user
      assert_equal issues(:issue1).title, assigns(:talk).issue.title
      assert_equal 'http://link.xx', assigns(:talk).reference.url
    end
  end

  test '다른 논의에서 레퍼런스하던 링크로 고칠 수 있어요' do
    talk3_link = talks(:talk3).reference.url
    stub_crawl(talk3_link) do
      sign_in(users(:one))

      put talk_path(talks(:talk1)), talk: { body: 'body', reference_attributes: { url: talk3_link }, reference_type: 'LinkSource' }
      refute assigns(:talk).errors.any?
      assert_equal talks(:talk3).reference, assigns(:talk).reference
      assert Talk.exists?(id: talks(:talk1).id)
    end
  end

  test '최근 새로 걸린 링크의 주소로 고쳐요' do
    talk1_link = talks(:talk1).reference.url
    stub_crawl(talk1_link) do
      sign_in(users(:one))

      put talk_path(talks(:talk3)), talk: { body: 'body', reference_attributes: { url: talk1_link }, reference_type: 'LinkSource' }
      refute assigns(:talk).errors.any?
      assert_equal talks(:talk3), assigns(:talk)
      assert_equal talks(:talk1).reference, talks(:talk3).reload.reference
      assert Talk.exists?(id: talks(:talk1).id)
    end
  end

end
