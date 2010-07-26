class CalendarController < ApplicationController
  before_filter :private_global
  include Icalendar
  
  before_filter :login_required, :except => [ :subscribe ]
  layout 'calendar'
  def subscribe
    @member = Member.find_by_uuid(params[:uuid])
    headers['Content-Type'] = "text/calendar"
    headers['Cache-Control'] =  "max-age=120"
    @invites = Invitation.find(:all, :conditions => ['member_id = ? and (events.start_time > ? or (events.recurrence_frequency IS NOT NULL AND events.recurrence_frequency != "")) and (events.deactivated != 1)', @member.id, Time.now.utc], :include => :meetings)
    @meetings = @invites.collect{ |invite| invite.future_meetings }
    @meetings << @member.upcoming_and_confirmed(@univ_account)
    @meetings.flatten!
	@meetings.uniq!
    @calendar = Icalendar::Calendar.new
    @meetings.each do |meeting|
         if !meeting.nil?
           event = Icalendar::Event.new
           event.start = DateTime.parse(meeting.start_time_local.to_s)
           event.end = DateTime.parse(meeting.end_time_local.to_s)
           event.summary = meeting.invitation.name
           event.attendees = Array(meeting.attending_members.collect { |member| member.fullname }.join(", "))
           event.organizer = meeting.invitation.inviter.user_name 
           event.description = (meeting.invitation.description.gsub(/\r\n/m, ' ') rescue '')
           event.location = (meeting.invitation.address.summary rescue '--')
           event.url = show_invite_url(:id => meeting.invitation.id, :meeting_id => meeting.id)
           @calendar.add event
         end
    end
    @calendar.ip_method = "PUBLISH"
    render :layout => false
  end
  
  def index
    @member = current_member      
  end
  
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
    end
  end

end
