class Admin::LandingPagesController < AdminController
  def index
    @sections = LandingPage.all_data
  end

  def save
    sections = ['recent_posts', 'polls', 'surveys', 'wikis']

    sections.each do |section|
      landingPage = LandingPage.new
      if params[section].present?
        LandingPage.find_by(section: section).try(:destroy)

        section_body = params[section].gsub(/\s+/, "").split(',').compact.to_json
        landingPage.assign_attributes(section: section, body: section_body)
        landingPage.save!
      end
    end

    flash[:success] = I18n.t('activerecord.successful.messages.created')
    redirect_to admin_landing_pages_path and return
  end

  def fetch_posts
    public_recent_posts = Post.of_searchable_issues.where('posts.created_at > ?', (Date.today - 15))

    @recent_posts = public_recent_posts.where('posts.file_sources_count > 0')
    @wikis = public_recent_posts.having_wiki
    @polls_or_surveys = public_recent_posts.having_poll.or(public_recent_posts.having_survey)
  end

end
