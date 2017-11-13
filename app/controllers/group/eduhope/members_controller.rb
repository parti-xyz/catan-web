class Group::Eduhope::MembersController < GroupBaseController
  before_filter :authenticate_user!

  def admit
    @member = MemberGroupService.new(group: current_group, user: current_user, description: params[:description]).call
    if @member.persisted?
      MemberMailer.deliver_all_later_on_create(@member)
    end
    redirect_to(request.referrer || root_path)
  end
end
