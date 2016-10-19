class Admin::UsersController < AdminController
  def all_email
    @results = User.pluck(:email).uniq.map{|email| [User.find_by(email: email).nickname, email] }
    respond_to do |format|
      format.xlsx
    end
  end
end
