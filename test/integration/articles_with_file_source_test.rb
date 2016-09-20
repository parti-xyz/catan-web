require 'test_helper'

class ArticlesWithFileSourceTest < ActionDispatch::IntegrationTest

  test '만들어요' do
    sign_in(users(:one))

    post articles_path, article: { issue_id: issues(:issue2).id, body: 'body', source_attributes: { attachment: fixture_file('files/sample.pdf') }, source_type: 'FileSource' }

    assert assigns(:article).persisted?
    assigns(:article).reload

    assert_equal users(:one), assigns(:article).user
    assert_equal 'sample.pdf', assigns(:article).source.name
    assert_equal issues(:issue2).title, assigns(:article).issue.title
    assert_equal 'body', assigns(:article).body

    assert assigns(:article).comments.empty?
  end

  test '10mb초과하는 파일은 업로드할 수 없어요' do
    sign_in(users(:one))

    post articles_path, article: { issue_id: issues(:issue2).id, body: 'body', source_attributes: { attachment: fixture_file('files/sample_over_10mb.pdf') }, source_type: 'FileSource' }

    refute assigns(:article).persisted?
  end

  test '고쳐요' do
    sign_in(users(:one))

    put article_path(articles(:article5)), article: { body: 'body', issue_id: issues(:issue1).id, source_attributes: { attachment: fixture_file('files/sample.pdf')}, source_type: 'FileSource' }

    refute assigns(:article).errors.any?
    assigns(:article).reload
    assert_equal 'body', assigns(:article).body
    assert_equal users(:one), assigns(:article).user
    assert_equal issues(:issue1).title, assigns(:article).issue.title
    assert_equal 'sample.pdf', assigns(:article).source.name
  end

  test '기존 파일을 그대로 두고 고쳐요' do
    sign_in(users(:one))

    original_name = articles(:article5).reload.source.name

    put article_path(articles(:article5)), article: { body: 'new body', source_attributes: {id: articles(:article5).source.id} }
    refute assigns(:article).errors.any?
    assigns(:article).reload
    assert_equal 'new body', assigns(:article).body
    assert_equal original_name, assigns(:article).source.name
  end

  test '세상에 없는 빠띠를 넣으면 저장이 안되요' do
    sign_in(users(:one))

    previous_count = Article.count

    assert_raises CanCan::AccessDenied do
      post articles_path, article: { body: 'body', source_attributes: { attachment: fixture_file('files/sample.pdf') }, source_type: 'FileSource', issue_id: -1}
    end
    assert_equal previous_count, Article.count
  end

  test '본문이 없어도 만들어요' do
    sign_in(users(:one))

    post articles_path, article: { source_attributes: { attachment: fixture_file('files/sample.pdf')}, source_type: 'FileSource', issue_id: issues(:issue2).id }

    assert assigns(:article).persisted?
  end
end
