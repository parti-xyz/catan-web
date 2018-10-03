class Event < ApplicationRecord
  attr_accessor :start_at_time
  attr_accessor :start_at_date
  attr_accessor :end_at_time
  attr_accessor :end_at_date
  attr_accessor :unfixed_schedule
  attr_accessor :unfixed_location

  has_many :roll_calls, dependent: :nullify
  has_one :post, dependent: :destroy
  has_many :messages, as: :messagable, dependent: :destroy

  after_find :setup_schedule_accessors
  after_find :setup_location_accessors
  validates :unfixed_schedule, inclusion: { in: [true, false] }
  validates :unfixed_location, inclusion: { in: [true, false] }

  def setup_schedule
    if unfixed_schedule
      self.start_at = nil
      self.end_at = nil
      self.all_day_long = false
    else
      self.start_at = strptime_schedule(self.start_at_date, self.start_at_time, self.all_day_long)
      self.end_at = strptime_schedule(self.end_at_date, self.end_at_time, self.all_day_long)
    end
  end

  def setup_location
    if unfixed_location
      self.location = nil
    end
  end

  def attend?(someone)
    self.roll_calls.exists?(user: someone, status: :attend)
  end

  def absent?(someone)
    self.roll_calls.exists?(user: someone, status: :absent)
  end

  def to_be_decided?(someone)
    self.roll_calls.exists?(user: someone, status: :to_be_decided)
  end

  def takable_self_roll_call?(someone)
    !self.post.issue.blind_user?(someone) and (self.post.user == someone or self.roll_calls.exists?(user: someone) or (self.enable_self_attendance? and self.post.issue.member?(someone)) )
  end

  def invitable_by?(someone)
    !self.post.issue.blind_user?(someone) and attend?(someone) or self.post.user == someone
  end

  def invited?(someone)
    self.roll_calls.exists?(user: someone, status: :invite)
  end

  def invitable_softly_for?(someone)
    self.post.issue.member?(someone) and !self.post.issue.blind_user?(someone)
  end

  def taken_roll_call?(someone)
    self.roll_calls.exists?(user: someone)
  end

  def roll_call_of(someone)
    self.roll_calls.find_by(user: someone)
  end

  def unfixed_start_ant_end?
    start_at.blank? and end_at.blank?
  end

  def unfixed_schedule=(value)
    @unfixed_schedule = ActiveRecord::Type::Boolean.new.cast(value)
  end

  def unfixed_location=(value)
    @unfixed_location = ActiveRecord::Type::Boolean.new.cast(value)
  end

  def only_one_day?
    self.all_day_long and self.start_at_date = self.end_at_date
  end

  def need_to_rsvp?
    return :rsvp_schedule if self.will_save_change_to_start_at? or
      self.will_save_change_to_end_at? or
      self.will_save_change_to_all_day_long?
    return :rsvp_location if self.will_save_change_to_location?
    return false
  end

  def issue_for_message
    self.post.issue
  end

  def group_for_message
    self.post.issue.group
  end

  def end_at_compact
    diff_hash = end_schedule_diffed_with_start_schedule
    %i(year month day am_pm hour min).map { |key| diff_hash[key] }.compact.join(' ')
  end

  private

  def setup_schedule_accessors
    if self.start_at.present?
      self.start_at_date, self.start_at_time = strftime_schedule(self.start_at, self.all_day_long)
    end
    if self.end_at.present?
      self.end_at_date, self.end_at_time = strftime_schedule(self.end_at, self.all_day_long)
    end

    self.unfixed_schedule = unfixed_start_ant_end?
  end

  def setup_location_accessors
    self.unfixed_location = (self.location.blank?)
  end

  def strptime_schedule(at_date, at_time, all_day_long)
    if all_day_long
      DateTime.strptime(at_date, '%Y년 %m월 %e일')
    else
      full_string = "#{at_date} #{at_time}".gsub(/오후/, 'PM').gsub(/오전/, 'AM')
      DateTime.strptime(full_string, '%Y년 %m월 %e일 %p %l:%M')
    end
  rescue ArgumentError => e
    return nil
  end

  def strftime_schedule(datetime, all_day_long)
    date_string = datetime.strftime('%Y년 %m월 %e일')
    time_string = nil
    unless all_day_long
      min = (datetime.min == 0 ? '' : "#{datetime.min}분")
      time_string = datetime.strftime("%p %l시 #{min}")
      time_string = time_string.gsub(/PM/, '오후').gsub(/AM/, '오전')
    end
    [ date_string, time_string ]
  rescue ArgumentError => e
    return nil
  end

  def end_schedule_diffed_with_start_schedule
    return {} if end_at.blank?

    result = { year: "#{end_at.year}년", month: "#{end_at.month}월", day: "#{end_at.day}일" }
    unless self.all_day_long
      min = (end_at.min == 0 ? '' : "#{end_at.min}분")
      am_pm = end_at.strftime('%p').gsub(/PM/, '오후').gsub(/AM/, '오전')
      result.merge!(hour: end_at.strftime('%l시'), min: min, am_pm: am_pm)
    end

    return result if start_at.blank? or start_at.year != end_at.year
    result.delete(:year)

    if start_at.month != end_at.month
      return result
    end
    result.delete(:month)

    if start_at.day != end_at.day
      return result
    end
    result.delete(:day)

    result result if result.blank?

    if start_at.hour != end_at.hour
      return result
    end
    result.delete(:hour)
    result.delete(:am_pm)

    if start_at.min != end_at.min
      return result
    end

    return {}
  end
end
