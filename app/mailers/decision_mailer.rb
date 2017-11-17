class DecisionMailer < ApplicationMailer
  def self.deliver_all_later_on_update(decision_history)
    histories_chunk = []
    current_history = decision_history
    while(1) do
      previous_history = current_history.previous_of_current_post
      break if previous_history.nil?
      break if previous_history.user != current_history.user
      break if (current_history.created_at.to_i - previous_history.created_at.to_i) > 5 * 60
      histories_chunk << previous_history
      current_history = previous_history
    end

    not_sent_histories = histories_chunk.select { |decision_history| decision_history.mailed_at.blank? }
    if histories_chunk.blank? or not_sent_histories.any?
      post = Post.find_by(id: decision_history.post_id)
      post.messagable_users.each do |user|
        next if decision_history.user == user
        on_update(decision_history.id, user.id).deliver_later
      end
    end

    decision_history.update_columns(mailed_at: DateTime.now)
    not_sent_histories.each do |decision_history|
      decision_history.update_columns(mailed_at: DateTime.now)
    end
  end

  def on_update(decision_history_id, user_id)
    @decision_history = DecisionHistory.find_by(id: decision_history_id)
    return if @decision_history.blank?

    @post = Post.find_by(id: @decision_history.post_id)
    @user = User.find_by(id: user_id)
    return if @post.blank? or @user.blank? or !@user.enable_mailing_poll_or_survey? or @user.email.blank?

    mail(to: @user.email,
      subject: "[빠띠] \"#{@post.specific_desc_striped_tags(50)}\" 게시글의 결정사항이 업데이트되었습니다.")
  end
end
