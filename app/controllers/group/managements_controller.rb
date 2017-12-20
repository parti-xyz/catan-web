class Group::ManagementsController < GroupBaseController
  before_action :only_organizer, only: [:index]

  def index
    organizer_group = Group.find_by(slug: 'organizer')
    @posts_pinned = organizer_group.pinned_posts(current_user)
  end
end
