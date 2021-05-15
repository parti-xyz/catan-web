class Admin::GroupsController < Admin::BaseController
  def index
    @groups = Group.recent.page(params[:page])

    if params[:q].present?
      @groups = @groups.search_for(params[:q])
    end
  end

  def destroy
    @group = Group.find_by(id: params[:id])
    return(render_404) if @group.blank? || @group.open_square?
    if params[:site_title] != @group.title
      flash[:alert] = '그룹의 제목이 일치하지 않습니다'
      return redirect_back(fallback_location: admin_groups_path)
    end

    message = '요청에 의해 삭제합니다'
    ActiveRecord::Base.transaction do
      GroupDestroyJob.perform_async(current_user.id, @group.id, message)
      flash[:success] = I18n.t('activerecord.successful.messages.will_delete')
      redirect_back(fallback_location: admin_groups_path)
    end
  end

  def update_plan
    @group = Group.find_by(id: params[:id])
    return render_404 if @group.blank?

    @group.update_attributes(plan: params[:plan])
    redirect_back(fallback_location: admin_groups_path)
  end

  def update_slug
    @group = Group.find_by(id: params[:id])
    return render_404 if @group.blank?

    ActiveRecord::Base.transaction do
      if Group.exists?(slug: params[:slug])
        flash[:alert] = '해당 주소가 이미 존재합니다.'
        return redirect_back(fallback_location: admin_groups_path)
      end

      User.where(touch_group_slug: @group.slug).update_all(touch_group_slug: params[:slug])
      Category.where(group_slug: @group.slug).update_all(group_slug: params[:slug])
      Issue.where(group_slug: @group.slug).update_all(group_slug: params[:slug])
      @group.update_attributes(slug: params[:slug])
    end

    flash[:notice] = '변경했습니다.'
    redirect_back(fallback_location: admin_groups_path)
  end

  def blind
    group = Group.find_by(slug: params[:group_to_be_blind])
    if group.blank?
      flash[:error] = '그룹을 찾을 수 없습니다. 정확한 slug를 입력해주세요.'
      redirect_to admin_groups_path and return
    end
    group.blinded_at = DateTime.now
    group.blinded_by = current_user

    if group.save
      flash[:success] = '블라인드처리 완료했습니다.'
      redirect_to admin_groups_path
    else
      flash[:success] = '블라인드처리 못했습니다.'
      redirect_to admin_groups_path
    end
  end

  def unblind
    group = Group.find_by(id: params[:id])
    if group.blank?
      flash[:error] = '그룹을 찾을 수 없습니다.'
      redirect_to admin_groups_path and return
    end
    group.blinded_at = nil
    group.blinded_by = nil

    if group.save
      flash[:success] = '블라인드 취소처리 완료했습니다.'
      redirect_to admin_groups_path
    else
      flash[:success] = '블라인드 취소처리 못했습니다.'
      redirect_to admin_groups_path
    end
  end
end
