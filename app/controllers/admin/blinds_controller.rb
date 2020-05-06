class Admin::BlindsController < Admin::BaseController
  load_and_authorize_resource

  def index
    @blind = Blind.new
    @blinds = Blind.site_wide_only
  end

  def create
    @blind.user = User.find_by(nickname: @blind.nickname)
    deprecated_errors_to_flash(@blind) unless @blind.save
    redirect_to admin_blinds_path
  end

  def destroy
    deprecated_errors_to_flash(@blind) unless @blind.destroy
    redirect_to admin_blinds_path
  end

  private

  def blind_params
    params.require(:blind).permit(:nickname)
  end
end
