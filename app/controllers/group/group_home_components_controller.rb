class Group::GroupHomeComponentsController < Group::BaseController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :only_organizer

  def new
  end

  def create
    @group_home_component = current_group.group_home_components.build(group_home_component_params)
    @group_home_component.seq_no = (current_group.group_home_components.maximum(:seq_no) || 0) + 1

    ActiveRecord::Base.transaction do
      if @group_home_component.save
        arrange_seq_group_home_components!
      else
        errors_to_flash(@group_home_component)
      end
    end
  end

  def edit
  end

  def update
    ActiveRecord::Base.transaction do
      if @group_home_component.update_attributes(group_home_component_params)
        arrange_seq_group_home_components!
      else
        errors_to_flash(@group_home_component)
      end
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @group_home_component.destroy
        arrange_seq_group_home_components!
      else
        errors_to_flash(@group_home_component)
      end
    end
  end

  def destroy_all
    unless current_group.group_home_components.destroy_all
      errors_to_flash(current_group)
    end
  end

  def up_seq
    old_seq_no = @group_home_component.seq_no
    new_seq_no = old_seq_no - 1

    switching_group_home_component_ids = @group_home_component.group.group_home_components.where(seq_no: new_seq_no).select(:id).to_a

    ActiveRecord::Base.transaction do
      GroupHomeComponent.where(id: switching_group_home_component_ids).update_all(seq_no: old_seq_no)
      if @group_home_component.update_attributes(seq_no: new_seq_no)
        arrange_seq_group_home_components!
      else
        errors_to_flash(@group_home_component)
      end
    end
  end

  def down_seq
    old_seq_no = @group_home_component.seq_no
    new_seq_no = old_seq_no + 1

    switching_group_home_component_ids = @group_home_component.group.group_home_components.where(seq_no: new_seq_no).select(:id).to_a

    ActiveRecord::Base.transaction do
      GroupHomeComponent.where(id: switching_group_home_component_ids).update_all(seq_no: old_seq_no)
      if @group_home_component.update_attributes(seq_no: new_seq_no)
        arrange_seq_group_home_components!
      else
        errors_to_flash(@group_home_component)
      end
    end
  end

  private

  def arrange_seq_group_home_components!
    current_group.arrange_seq_group_home_components!
  end

  def group_home_component_params
    params.require(:group_home_component).permit(:title, :format_name, issue_posts_format_attributes: [ :issue_id ])
  end
end
