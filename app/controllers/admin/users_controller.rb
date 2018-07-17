class Admin::UsersController < Admin::BaseController
  def all_email
    @results = User.pluck(:email).uniq.map{|email| [User.find_by(email: email).nickname, email] }
    respond_to do |format|
      format.xlsx
    end
  end

  def stat
    begin
      @from = params[:from].try(:to_date)
    rescue ArgumentError => e
    end
    @from ||= 10.days.ago.to_date

    begin
      @to = params[:to].try(:to_date)
    rescue ArgumentError => e
    end
    @to ||= Date.today

    if @from > @to
      @from, @to = @to, @from
    end

    @user = User.find_by nickname: params[:user_nickname]
    if @user.present?
      @data = [Post, Comment, Upvote].map do |m|
        selected = m.between_times(@from, @to).where(user: @user).group_by_day("#{m.model_name.plural}.created_at").count
        [
          m,
          Hash[(@from ... @to).map { |date| [date, selected[date] || 0] }]
        ]
      end
    end
  end

  def index
    if params[:user_nickname].present?
      @users = User.where(nickname: params[:user_nickname])
    elsif params[:user_email].present?
      @users = User.where(email: params[:user_email])
    else
      @users = User.page(params[:page])
    end

  end

end
