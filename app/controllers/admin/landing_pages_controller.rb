class Admin::LandingPagesController < AdminController
  def index
    @posts = Post.of_public_issues_of_public_group
                 .where('posts.created_at > ? and posts.file_sources_count > 0', (Date.today - 15))
  end

  def save
    sections = ['recent_posts', 'discusstions', 'wikis']

    sections.each do |section|
      landingPage = LandingPage.new
      if params[section].present?
        LandingPage.where(section: section).destroy_all
        landingPage.assign_attributes({ :section => section, :body => params[section].to_json })
        landingPage.save!
      end
    end

    flash[:success] = I18n.t('activerecord.successful.messages.created')
    redirect_to admin_landing_pages_path and return

  end

end
