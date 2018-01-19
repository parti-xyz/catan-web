class LandingPage < ActiveRecord::Base
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
end
