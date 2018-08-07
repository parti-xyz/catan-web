class Admin::LandingPagesController < Admin::BaseController
  def index
    @sections = LandingPage.all_data
  end

  def save
    sections = ['recent_posts', 'polls', 'surveys', 'wikis', 'subject1', 'subject2', 'subject3', 'subject4',
                'subject5', 'subject6', 'subject7', 'subject8', 'subject9', 'subject10']
    sidx = 0;

    landing_pages  = []

    ActiveRecord::Base.transaction do
      sections.each do |section|
        landing_page = LandingPage.new

        if params[section].present?
          LandingPage.find_by(section: section).try(:destroy)
          section_body = params[section].gsub(/\s+/, "").split(',').compact.to_json
          section_title = params[section + "_title"] if section.include? 'subject'

          landing_page.assign_attributes(section: section, body: section_body, title: section_title)
          landing_page.save
          landing_pages << landing_page
        end
      end
    end

    landing_pages.each do |landing_page|
      if landing_page.errors.any?
        errors_to_flash(landing_page)
        @sections = LandingPage.all_data(landing_pages)
        render "admin/landing_pages/index"
        return
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
