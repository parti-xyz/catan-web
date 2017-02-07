class Group::MembersController < ApplicationController
  def index
    @users = current_group.member_users
  end
end
