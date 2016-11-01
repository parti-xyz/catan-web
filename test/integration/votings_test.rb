require 'test_helper'

class VotingsTest < ActionDispatch::IntegrationTest

  test '만들어요' do
    sign_in users(:one)

    post poll_votings_path(poll_id: polls(:poll1).id, voting: { choice: :agree })

    assert assigns(:voting).persisted?
    assert_equal users(:one), assigns(:voting).user
    assert_equal 'agree', assigns(:voting).choice
  end

  test '같은 사람이 투표를 여러 번 해도 투표 건 수는 하나랍니다' do
    previous_count = polls(:poll1).votings.count
    assert polls(:poll1).votinged_by? users(:two)

    sign_in users(:two)
    post poll_votings_path(poll_id: polls(:poll1).id, voting: { choice: :agree })

    assert_equal previous_count, polls(:poll1).votings.count
  end
  focus
  test '투표를 바꿔요' do
    assert polls(:poll1).agreed_by? users(:two)

    sign_in users(:two)
    post poll_votings_path(poll_id: polls(:poll1).id, voting: { choice: :disagree })

    refute polls(:poll1).reload.agreed_by? users(:two)
  end
end