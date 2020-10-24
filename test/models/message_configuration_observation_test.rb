require 'test_helper'

class MessageConfigurationObservationTest < ActiveSupport::TestCase
  test '멘션 받을 사용자 찾기' do
    group_alpha = groups(:alpha)
    user_one = users(:one)

    group_observation = MessageConfiguration::GroupObservation.of(user_one, group_alpha)
    assert group_observation.new_record?

    users = User.observing_message(group_alpha, :mention, [:subscribing, :subscribing_and_app_push])
    assert users.exists?(id: user_one)

    group_observation.payoff_mention = :ignoring
    group_observation.save

    users = User.observing_message(group_alpha, :mention, [:subscribing, :subscribing_and_app_push])
    assert_not users.exists?(id: user_one)
  end

  test '새글 메시지 받을 사용자 찾기' do
    issue1 = issues(:issue1)
    user_one = users(:one)

    issue_observation = MessageConfiguration::IssueObservation.of(user_one, issue1)
    assert issue_observation.new_record?

    users = User.observing_message(issue1, :create_post, [:subscribing, :subscribing_and_app_push])
    assert_not users.exists?(id: user_one)

    issue_observation.payoff_create_post = :subscribing
    issue_observation.save

    users = User.observing_message(issue1, :create_post, [:subscribing, :subscribing_and_app_push])
    assert users.exists?(id: user_one)
  end

  test '새 댓글 메시지 받을 사용자 찾기' do
    post1 = posts(:post1)
    user_one = users(:one)

    post_observation = MessageConfiguration::PostObservation.of(user_one, post1)
    assert post_observation.new_record?

    users = User.observing_message(post1, :create_comment, [:subscribing, :subscribing_and_app_push])
    assert_not users.exists?(id: user_one)

    post_observation.payoff_create_comment = :subscribing
    post_observation.save

    users = User.observing_message(post1, :create_comment, [:subscribing, :subscribing_and_app_push])
    assert users.exists?(id: user_one)
  end

  test '새 채널 메시지 받을 사용자 찾기' do
    group_alpha = groups(:alpha)
    user_one = users(:one)
    user_two = users(:two)

    group_observation = MessageConfiguration::GroupObservation.of(user_one, group_alpha)
    assert group_observation.new_record?

    issue = Issue.new(slug: 'new', group_slug: group_alpha.slug)
    IssueCreateService.new(issue: issue, current_user: user_two, current_group: group_alpha, flash: nil).call
    users = User.observing_message(issue, :create_issue, MessageObservationConfigurable.all_subscribing_payoffs)
    assert_not users.exists?(id: user_one)

    group_observation.payoff_create_issue = :subscribing
    group_observation.save

    users = User.observing_message(issue, :create_issue, MessageObservationConfigurable.all_subscribing_payoffs)
    assert users.exists?(id: user_one)
  end

  test '설정 재정의' do
    post1 = posts(:post1)
    user_one = users(:one)

    post_observation = MessageConfiguration::PostObservation.of(user_one, post1)
    assert post_observation.new_record?

    assert_equal :ignoring, post_observation.all_configurations[:create_comment]

    group_observation = MessageConfiguration::GroupObservation.of(user_one, post1.issue.group)
    group_observation.payoff_create_comment = 'subscribing_and_app_push'
    group_observation.save

    assert_equal :subscribing_and_app_push, post_observation.all_configurations[:create_comment]

    post_observation.payoff_create_comment = 'subscribing'
    post_observation.save

    assert_equal :subscribing, post_observation.all_configurations[:create_comment]
  end

  test '각 스콥에 맞는 설정' do
    post1 = posts(:post1)
    user_one = users(:one)

    post_observation = MessageConfiguration::PostObservation.of(user_one, post1)
    assert post_observation.new_record?

    assert_not post_observation.all_configurations.key?(:mention)
  end

  test '오거나이저 설정' do
    group_alpha = groups(:alpha)
    root_observation = MessageConfiguration::RootObservation.of(group_alpha)
    assert root_observation.new_record?
    assert_equal :subscribing_and_app_push, root_observation.all_configurations[:mention]
  end
end
