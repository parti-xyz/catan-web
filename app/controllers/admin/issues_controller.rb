class Admin::IssuesController < Admin::BaseController
  def merge
    group = Group.find_by slug: params[:group_slug]
    if group.blank?
      flash[:error] = '그룹 슬러그를 확인해 주세요'
      redirect_to admin_issues_path and return
    end

    source = Issue.find_by slug: params[:source_slug], group_slug: group.slug
    target = Issue.find_by slug: params[:issue_slug], group_slug: group.slug
    if source.blank? or target.blank?
      flash[:error] = '채널을 찾을 수 없습니다. 혹시 다른 그룹의 채널인가요?'
      redirect_to admin_issues_path and return
    end

    ActiveRecord::Base.transaction do
      MergedIssue.where(issue: source).update_all(issue_id: target.id)
      MergedIssue.create!(source_id: source.id, source_group_slug: source.group_slug, source_slug: source.slug, issue: target, user: current_user)

      # members : joinable_id
      ActiveRecord::Base.record_timestamps = false
      begin
        source.members.each do |member|
          user = member.user
          unless target.member_users.exists?(id: user.id)
            MemberIssueService.new(issue: target, user: user, updated_at: member.updated_at, created_at: member.created_at, need_to_message_organizer: false, is_force: true).call
          end
        end
      ensure
        ActiveRecord::Base.record_timestamps = true
      end

      # member_requests : joinable_id
      ActiveRecord::Base.record_timestamps = false
      begin
        source.member_requests.each do |member_request|
          user = member_request.user
          target.member_requests.build(user: user, updated_at: member_request.updated_at, created_at: member_request.created_at) unless target.member_request_users.exists?(id: user.id)
        end
      ensure
        ActiveRecord::Base.record_timestamps = true
      end

      # blinds :issue_id
      source.blind_users.each do |user|
        target.blinds.build(user: user) unless target.blind_users.exists?(id: user.id)
      end

      # relateds : issue_id
      source.relateds.each do |related|
        if related.target == target
          next
        end
        if target.relateds.exists?(target: related.target)
          next
        end
        target.relateds.build(target: related.target)
      end
      target.save!

      # messagable_id : messagable_id
      ActiveRecord::Base.record_timestamps = false
      begin
        Message.where(messagable_id: source.id, messagable_type: 'Issue').update_all(messagable_id: target.id)
      ensure
        ActiveRecord::Base.record_timestamps = true
      end

      # folders
      ActiveRecord::Base.record_timestamps = false
      begin
        source.folders.each do |source_folder|
          if target.folders.exists?(title: source_folder.title)
            source_folder.update(title: "#{source_folder.title}-복사됨")
          end
          source_folder.update(issue_id: target.id)
        end
      ensure
        ActiveRecord::Base.record_timestamps = true
      end

      # posts : issue_id
      ActiveRecord::Base.record_timestamps = false
      begin
        source.posts.update_all(issue_id: target.id)

        # upvotes : issue_id
        Upvote.where(issue: source).each do |upvote|
          upvote.update_columns(issue_id: target.id, updated_at: upvote.updated_at)
        end

      ensure
        ActiveRecord::Base.record_timestamps = true
      end

      source.reload.destroy!

      Issue.reset_counters(target.id, :posts, :members)
    end

    flash[:success] = '완료했습니다.'
    redirect_to admin_issues_path
  end

  def ice
    issue = Issue.of_slug(params[:issue_to_be_iced], params[:issue_to_be_iced_of_group])
    if issue.blank?
      flash[:error] = '채널을 찾을 수 없습니다. 정확한 slug를 입력해주세요.'
      redirect_to admin_issues_path and return
    end
    issue.iced_at = Time.current

    if issue.save
      flash[:success] = '휴면 표시를 완료했습니다.'
      redirect_to admin_issues_path
    else
      flash[:success] = '휴면 표시를 완료하지 못했습니다.'
      redirect_to admin_issues_path
    end
  end

  def blind
    issue = Issue.of_slug(params[:issue_to_be_blind], params[:issue_to_be_blind_of_group])
    if issue.blank?
      flash[:error] = '채널을 찾을 수 없습니다. 정확한 slug를 입력해주세요.'
      redirect_to admin_issues_path and return
    end
    issue.blinded_at = Time.current
    issue.blinded_by = current_user

    if issue.save
      flash[:success] = '블라인드처리 완료했습니다.'
      redirect_to admin_issues_path
    else
      flash[:success] = '블라인드처리 못했습니다.'
      redirect_to admin_issues_path
    end
  end

  def unblind
    issue = Issue.find_by(id: params[:id])
    if issue.blank?
      flash[:error] = '채널을 찾을 수 없습니다.'
      redirect_to admin_issues_path and return
    end
    issue.blinded_at = nil
    issue.blinded_by = nil

    if issue.save
      flash[:success] = '블라인드 취소처리 완료했습니다.'
      redirect_to admin_issues_path
    else
      flash[:success] = '블라인드 취소처리 못했습니다.'
      redirect_to admin_issues_path
    end
  end
end
