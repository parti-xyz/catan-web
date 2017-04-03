class Talk < ActiveRecord::Base
  acts_as_paranoid
  acts_as :post, as: :postable

  belongs_to :poll
  accepts_nested_attributes_for :poll

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, -> { after(1.day.ago) }
  scope :having_poll, -> { where.not(poll_id: nil) }
  scope :previous_of_recent, ->(post) {
    base = recent
    base = base.where('posts.created_at < ?', post.created_at) if post.present?
    base
  }

  attr_accessor :has_poll
  attr_accessor :is_html_body



  def parsed_title
    title, _ = parsed_title_and_body
    title
  end

  def parsed_body
    _, body = parsed_title_and_body
   body
  end

  def commenters
    comments.map(&:user).uniq.reject { |u| u == self.user }
  end

  def build_poll(params)
    if self.poll.try(:persisted?)
      self.poll.assign_attributes(params)
    else
      self.poll = Poll.new(params) if self.has_poll == 'true'
    end
  end

  def voting_by voter
    poll.try(:voting_by, voter)
  end

  def voting_by? voter
    poll.try(:voting_by?, voter)
  end

  def agreed_by? voter
    poll.try(:agreed_by?, voter)
  end

  def disagreed_by? voter
    poll.try(:disagreed_by?, voter)
  end

  def sured_by? voter
    poll.try(:sured_by?, voter)
  end

  def unsured_by? voter
    poll.try(:unsured_by?, voter)
  end

  private

  def parsed_title_and_body
    strip_body = body.try(:strip)
    strip_body = '' if strip_body.nil?
    if link_source.present? || poll.present?
      [nil, body]
    elsif strip_body.length < 100
      [body, nil]
    elsif strip_body.length < 250
      [nil, body]
    else
      lines = strip_body.lines
      setences = lines.first.split(/(?<=\<\/p>)/)
      if setences.first.length < 100
        remains = (setences[1..-1] + lines[1..-1]).join
        [setences.first, remains]
      else
        [nil, body]
      end
    end
  end
end
