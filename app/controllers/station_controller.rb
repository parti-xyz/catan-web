class StationController < ApplicationController
  layout 'bpplication'

  def show
  end

  def navbar
    @groups = current_user&.member_groups || ActiveRecord.none
    render template: 'station/_navbar', layout: false
  end
end
