require 'test_helper'

class FolderTest < ActionDispatch::IntegrationTest
  test '게시글을 folder에 넣습니다' do
    #patch post_path(posts(:post_talk1)), post: { body: 'body x', issue_id: issues(:issue2).id }

    assert issues(:issue1), posts(:post_talk1).issue
    assert issues(:issue1), folders(:folder1).issue
    assert issues(:issue1).member? users(:three)
    sign_in(users(:three))

    patch update_folder_post_path(id: posts(:post_talk1).id, format: :js),
      params: { post: { folder_id: folders(:folder1).id } }

    assert folders(:folder1), assigns(:post).folder
  end

  test '게시글을 새로운 folder에 넣습니다' do
    #patch post_path(posts(:post_talk1)), post: { body: 'body x', issue_id: issues(:issue2).id }

    assert issues(:issue1), posts(:post_talk1).issue
    assert issues(:issue1), folders(:folder1).issue
    assert issues(:issue1).member? users(:three)
    sign_in(users(:three))

    patch update_folder_post_path(id: posts(:post_talk1).id, format: :js),
      params: { post: { folder_id: -1 }, new_folder: { title: '새폴더' } }

    assert assigns(:folder), assigns(:post).folder
    assert assigns(:folder).persisted?
  end

  test '다른 빠띠의 folder는 못 붙여요' do
    assert issues(:issue2), posts(:post_talk2).issue
    assert issues(:issue1), folders(:folder1).issue
    assert issues(:issue1).member? users(:one)
    sign_in(users(:one))

    patch update_folder_post_path(id: posts(:post_talk2).id, format: :js),
      params: { post: { folder_id: folders(:folder1).id } }

    assert_nil assigns(:post).folder
  end

  test 'folder에서 꺼내요' do
    assert issues(:issue1), posts(:post_talk5).issue
    assert issues(:issue1), folders(:folder1).issue
    assert issues(:issue1).member? users(:three)
    sign_in(users(:three))

    patch update_folder_post_path(id: posts(:post_talk5).id, format: :js),
      params: { post: { folder_id: '' } }

    assert_nil assigns(:post).folder
  end

  test 'folder 지워요' do
    assert issues(:issue1), posts(:post_talk1).issue
    assert issues(:issue1), folders(:folder1).issue
    assert issues(:issue1).member? users(:three)
    sign_in(users(:three))

    patch update_folder_post_path(id: posts(:post_talk1).id, format: :js),
      params: { post: { folder_id: folders(:folder1).id } }

    delete folder_path(id: folders(:folder1), format: :js)

    refute assigns(:folder).persisted?
  end
end
