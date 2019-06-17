class LandingPage < ApplicationRecord
  scope :section_for_issue_subject, ->{ where("section like 'subject%'") }

  validate :check_title_for_issue_subject

  def parsed_body
    return if body.blank?

    JSON.parse(body)
  end

  def body_in_form
    parsed_body.try(:join, ', ')
  end

  def self.all_data(source = nil)
    source = LandingPage.all.to_a if source.nil?
    Hash[source.map { |row| [ row.section.to_sym, row ] }]
  end

  def parsed_section_for_issue_subject
    return [] unless section.starts_with?("subject")
    return [] if parsed_body.blank?

    result = Issue.none
    parsed_body.each do |item|
      if item.include? "/"
        group_slug, issue_slug = item.split('/')
      else
        issue_slug = item
        group_slug = Group:DEFAULT_SLUG
      end

      result = result.or(Issue.where(slug: issue_slug, group_slug: group_slug))
    end
    result
  end

  def self.parsed_section_for_all_issue_subject(subjects)
    result = Issue.none
    self.section_for_issue_subject.where(title: subjects).map do |landing_page|
      result = result.or(landing_page.parsed_section_for_issue_subject)
    end
    result
  end

  private

  def check_title_for_issue_subject
    return unless self.section.starts_with?("subject")
    if self.title.length < 2 or self.title.include?(' ')
      errors.add(:title, I18n.t('errors.messages.wrong_parti_title', title: self.title))
    end
  end
end
