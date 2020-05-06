class Admin::GroupsController < Admin::BaseController
  def index
    @groups = Group.all.sort_by_name.page(params[:page])
  end

  def destroy
    @group = Group.find_by(id: params[:id])
    render_404 and return if @group.blank? or @group.open_square?

    if @group.destroy
      flash[:success] = I18n.t('activerecord.successful.messages.deleted')
    else
      deprecated_errors_to_flash @group
    end
    redirect_to admin_groups_path
  end

  def update_plan
    @group = Group.find_by(id: params[:id])
    render_404 and return if @group.blank?

    @group.update_attributes(plan: params[:plan])
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
