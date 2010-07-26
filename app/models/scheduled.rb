# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
# 
#  id                  :integer(11)   not null
#  invitation_id       :integer(11)
#  start_time          :datetime
#  end_time            :datetime
#  duration            :integer(11)
#  recurrence_frequency:string(255)
#  time_zone           :string(255)
#  runt_expression     :string(255)
#  next_occurrence     :datetime
# 
module TTB
 module Scheduled    
  include Runt
  def self.included(base)
   base.extend(Runt)
   base.composed_of :tz,
    :class_name => 'TimeZone',
    :mapping => %w(time_zone name)
   base.before_save :set_runt_expression, :calc_duration , :set_next_occurrence , :set_changed
   base.after_save :save_attributes  
   base.validate :validate_schedule

  end

  DATE_TEMPLATE_TEXT = 'MM/DD/YYYY HH:MM AM'

  RECURRENCE_OPTS = [ ['--', ''], %w{ Daily daily }, %w{ Weekdays weekdays}, %w{ Weekly  weekly },  %w{ Monthly monthly }, %w{ Yearly yearly } ]
  ATTRIBUTES_TO_WATCH =  [:time_zone, :start_time, :end_time, :recurrence_frequency]

  def after_initialize
   save_attributes
  end

  def save_attributes
   @mw_old_attributes = {}
   ATTRIBUTES_TO_WATCH.each do |attribute|
    @mw_old_attributes[attribute] = self.send(attribute) rescue nil
   end
  end

  def set_changed
   @mw_changed_attributes = ATTRIBUTES_TO_WATCH.select do |attribute|
    @mw_old_attributes[attribute]!= self.send(attribute) rescue nil
   end
  end

  def mw_changed_attributes
   @mw_changed_attributes
  end

  def changed?
   !( @changed_attributes.blank?)
  end

  def runt_expression
   @runt_expression ||= get_runt_expression(self.start_time_local, self.end_time_local, self.recurrence_frequency)
   @runt_expression
  end

  def set_runt_expression
   self.runt_expression =  @runt_expression = get_runt_expression(self.start_time_local, self.end_time_local, self.recurrence_frequency)
  end

  def calc_duration
   unless end_time.nil? or start_time.nil?
    self.duration = end_time - start_time
   end
  end

  def recurring?
   return !self.recurrence_frequency.blank?
  end
      
  def start_time_local
   @st ||= self.start_time.local_to_utc(self.time_zone)
  end
      
  def end_time_local
   @et ||= self.end_time.local_to_utc(self.time_zone)
  end

  def next_meeting_local(after_time = Time.now.utc)
   self.tz.utc_to_local(next_meeting(after_time))
  end

  def get_runt_expression(start_time, end_time, recurrence)
   expr = nil
   return expr if(start_time.nil? or end_time.nil?)
   case recurrence
   when 'daily'
    expr = REDay.new(start_time.hour, start_time.min, end_time.hour, end_time.min)
   when 'weekdays'
    expr = REWeek.new(Mon, Fri) & REDay.new(start_time.hour, start_time.min, end_time.hour, end_time.min)
   when 'weekly'
    expr = DIWeek.new(start_time.wday) & REDay.new(start_time.hour, start_time.min, end_time.hour, end_time.min)
   when 'monthly'
    week_index = (start_time.week_in_month < 5) ? start_time.week_in_month : -1
    expr = DIMonth.new(week_index, start_time.wday) & REDay.new(start_time.hour, start_time.min, end_time.hour, end_time.min)
   when 'yearly'
    month, day, week_in_month, wday = start_time.month, start_time.day, start_time.week_in_month, start_time.wday
    expr = REYear.new(month, day, month, day) & REDay.new(start_time.hour, start_time.min, end_time.hour, end_time.min) & DIMonth.new(week_in_month, wday)
   end
   expr
  end

  def recurrence_period
   case recurrence_frequency
   when 'daily'
    'day'
   when 'weekdays'
    'weekday'
   when 'monthly'
    'month'
   when 'weekly'
    'week'
   when 'yearly'
    'year'
   end
  end

  def future_occurances(max = 12, til = (Time.now + 12.years))
   future_occurances = []
   current_meeting = next_meeting()
   max.times do |t|
    yield current_meeting
    future_occurances << current_meeting
    current_meeting = next_meeting(current_meeting + 1.minute)
   end
   future_occurances
  end

  def start_time_local
   return (start_time.local_from_utc(time_zone) rescue nil)
  end

  def end_time_local
   return (end_time.local_from_utc(time_zone) rescue nil)
  end


  # I feel like the Runt library should have this built-in to the
  # TemporalExpression class, so I wouldn't have to make a schedule and add an
  # event and all of that down below.
  def next_meeting(after_time = Time.now.utc )
   # puts "Looking up next meeting after #{after_time}"
   if recurrence_frequency.blank?
    return start_time
   end

   if after_time < start_time
    return start_time
   end              

   after_time = after_time.local_from_utc(self.time_zone) 


   # Advance the starting time in the case when it falls after the beginning of
   # a meeting on the same day.  We do this so that we can use "day precision"
   # (PDate.day) in the Runt library instead of "minute precision" (PDate.min),
   # which performs terribly.
   start_time = start_time_local
   if(after_time.hour > start_time.hour or ( after_time.hour == start_time.hour and after_time.min > start_time.min))
    after_time = after_time + 1.day
    after_time = Time.gm(after_time.year, after_time.month, after_time.day, 0, 0)
   end

   case recurrence_frequency
   when 'daily'
    end_time = after_time + 25.hours  
    # after_time -= 1.day
    start_date = PDate.day(after_time.year, after_time.month, after_time.day , after_time.hour, after_time.min)
    end_date = PDate.day(end_time.year, end_time.month, end_time.day, end_time.hour, end_time.min)
   when 'weekdays'
    # Make the range over 3 days so that Friday night searches will still turn
    # up Monday as the next day.
    end_time = after_time + 3.days
    start_date = PDate.day(after_time.year, after_time.month, after_time.day, after_time.hour, after_time.min)
    end_date = PDate.day(end_time.year, end_time.month, end_time.day, end_time.hour, end_time.min)
   when 'monthly'
    eom = (after_time + 40.days)
    start_date = PDate.day(after_time.year, after_time.month, after_time.day)
    end_date = PDate.day(eom.year, eom.month, eom.day)
   when 'weekly'
    eow = (after_time + 8.days)
    start_date = PDate.day(after_time.year, after_time.month, after_time.day)
    end_date = PDate.day(eow.year, eow.month, eow.day)
   when 'yearly'
    # Just doing "after_time + 367.days" results in a bit of a performance hit
    # as hundreds of days are compared.   We'll try to narrow it a bit.  Not too
    # much, because we don't have time to actually write unit tests and make
    # sure the narrowing code works. :)  Which is why the comment is here.
    st = after_time + 250.days
    et = st + 150.days
    start_date = PDate.day(st.year, st.month, st.day)
    end_date = PDate.day(et.year, et.month, et.day)
   end                                 
   #  puts "     Range #{start_date.to_s} - #{end_date.to_s}"
   d_range = DateRange.new(start_date, end_date)
   sched = Schedule.new
   event = Event.new((self.invitation.name rescue "no name"))
   sched.add(event,self.runt_expression)
   dates = sched.dates(event,d_range)

   next_mtg = dates.first
   next_mtg_time = Time.gm(next_mtg.year, next_mtg.month, next_mtg.day, start_time_local.hour, start_time_local.min)
   result = nil
   begin
    result = next_mtg_time.local_to_utc(self.time_zone)
   rescue TZInfo::PeriodNotFound
    # This only happens when the time is during the one hour which is skipped
    # during the transition to DST.  For example, only on Sun Mar 08 02:15:00
    # (see ticket #744).
    next_hour = start_time_local.hour + 1
    next_mtg_time = Time.gm(next_mtg.year, next_mtg.month, next_mtg.day, next_hour, start_time_local.min)
    retry
   end
   return result
  end

  def set_next_occurrence
   return if (start_time.blank? or deactivated == true)
   if recurrence_frequency.blank?
    self.next_occurrence = start_time
   else
    self.next_occurrence = next_meeting(Time.now.utc)
   end
  end

  EMPTY_TIME_DATE_MESSAGE = "You must provide a start date and time in the form #{DATE_TEMPLATE_TEXT}."
  VALID_TIME = /^(\d{1,2})[\\\/\.-](\d{1,2})[\\\/\.-](\d{2}|\d{4})\s+(\d{1,2})[\. :](\d{2})\s?(am|pm)$/i
  def validate_end_time
   #~ if (end_time.blank?)
    #~ self.end_time = self.start_time + 1.hour
    #~ return
   #~ els
   if !end_time.nil?
     if(end_time < Time.now.utc and !recurring?)
      errors.add(:end_time, "cannot be in the past.")
      return false
     elsif end_time < start_time
      errors.add(:end_time, "cannot be earlier than the start time.")
      return false
     elsif(end_time.zone != "UTC")
      errors.add(:end_time, "must be in UTC.")
      return false
     end
   end 
  end

  def validate_start_time
   #~ if start_time.blank?
    #~ errors.add_to_base(EMPTY_TIME_DATE_MESSAGE)
    #~ return false
   #~ els
   if !start_time.nil?
     if(start_time < Time.now.utc and !recurring?)
      errors.add(:start_time, "cannot be in the past.")
      return false
     elsif(start_time.zone != "UTC")
      errors.add(:start_time, "must be in UTC.")
      return false
     end
     return true
   end
  end

  def validate_schedule
   # The end time validations (and their error messages) don't make sense unless
   # we have a valid start_time already, so we return if start_time validation
   # fails.
   return unless validate_start_time
   validate_end_time
  end

 end 
end
