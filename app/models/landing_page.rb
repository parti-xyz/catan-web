class LandingPage < ApplicationRecord
  scope :section_for_issue_subject, ->{ where("section like 'subject%'") }
  def parsed_body
    return if body.blank?

    JSON.parse(body)
  end

  def body_in_form
    parsed_body.try(:join, ', ')
  end

  def self.all_data
    Hash[LandingPage.all.to_a.map { |row| [ row.section.to_sym, row ] }]
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
        group_slug = 'indie'
      end

      result = result.or(Issue.where(slug: issue_slug, group_slug: group_slug))
    end
    result
  end
end
