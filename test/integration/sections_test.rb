require 'test_helper'

class SectionsTest < ActionDispatch::IntegrationTest
  test '일반주제는 삭제하지 못합니다' do
    sign_in(users(:maker))

    delete section_path(sections(:section1))

    assert assigns(:section).persisted?
  end

  test '일반주제가 아닌 주제를 삭제합니다' do
    sign_in(users(:maker))

    delete section_path(sections(:section3))

    refute assigns(:section).persisted?
  end

  test '일반주제가 아닌 주제인데 글이 있는 경우, 해당 글은 일반주제로 옮겨 갑니다' do
    sign_in(users(:maker))
    post = sections(:section4).posts.first
    assert_equal post.section, sections(:section4)

    delete section_path(sections(:section4))

    refute assigns(:section).persisted?
    post.reload
    refute_equal sections(:section4), post.section

    initial_section = sections(:section4).issue.initial_section
    assert_equal initial_section, post.section
  end
end
