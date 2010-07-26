#~ require 'ferret_around_invitation'
class Meeting < ActiveRecord::Base
  #~ include TTB::FerretAroundInvitation
  belongs_to :invitation
  has_many :confirmations
  has_many :messages
  has_many  :confirmed_invitees,
    :source => :member,
    :through => :confirmations,
    :conditions => ["status_id = 120"],
    :order => 'last_name', :group => 'member_id'
  has_many  :declined_invitees,
    :source => :member,
    :through => :confirmations,
    :conditions => ["status_id = 119"],
    :order => 'last_name', :group => 'member_id'
   
  #composed_of :tz, :class_name => 'TimeZone', :mapping => %w(time_zone name)    
    
  def is_in_future?
    self.start_time > Time.now.utc
  end     

 def for_romance?
    invitation.purpose == Purpose::ROMANCE
  end
  def is_public?
    return invitation.is_public
  end
	
  def is_private?
    return !invitation.is_public?
  end

  def open?
    return invitation.is_public?
  end
  
  def deactivated
   return invitation.deactivated
  end
	
  alias :is_private :is_private?
  alias :closed? :is_private?
  alias :open? :is_public?  
	
  def is_within_hours?  
    one_hour_ago = Time.now - 1.hour      
    twenty_four_hours_away = Time.now + 24.hours
    self.start_time > one_hour_ago.utc && self.start_time < twenty_four_hours_away.utc
  end
  def confirmations_for_invited_members
    confirmations.select(&:initially_invited?)
  end    
  
  def open?
   self.invitation.open?
  end
	
  def self.global_upcoming_invitations(limit = 12)
    self.find(:all, :conditions => [ "events.is_public = 1 AND events.draft_status = 'posted' AND meetings.start_time >= ? AND purpose_id != ?", Time.now.utc, Purpose::ROMANCE.id], 
      :order => 'meetings.start_time', :limit => limit, :include => [{:invitation =>:address}])
  end

  def self.find_near(city, state, country, opts = { } )
    sf = SearchFilter.new(:city => city, :state => state, :country => country, :start_date => Time.now, :radius => 100, :stars => opts[:stars])
    sf.full_text_search({ :limit => 25 , :use_invitation => true}, :include => SearchFilter::INVITATION_BROWSE_INCLUDES )
  end
	
  def invited_members
    confirmations_for_invited_members.map(&:member)#.sort_by(&:last_name)
  end

  def confirmations_for_people_requesting_invites
    confirmations.select {|c| c.status == Status['accepted'] }
  end

  def people_requesting_invites
    confirmations_for_people_requesting_invites.map(&:member) #.sort_by(&:last_name)
  end  
    
  def attending_confirmations
    confirmations.select{|conf| conf.status == Status[:confirmed]}
  end   
	
  def attending_members
    attending_confirmations.map(&:member) #.sort_by(&:last_name)
  end
	 
  def not_attending_confirmations
    confirmations.select(&:not_attending?)
  end		 
	
  def not_attending_members
    not_attending_confirmations.map(&:member)#.sort_by(&:last_name)
  end 
	
  def confirmations_for_people_declined
    confirmations.select {|c| c.rejected? }
  end
	
  def people_declined
    confirmations_for_people_declined.map(&:member)#.sort_by(&:last_name)
  end
	 
  def confirmations_for_people_requested_invites
    confirmations.reject(&:initially_invited?)
  end
	
  def people_requested_invites
    confirmations_for_people_requested_invites.map(&:member)#.sort_by(&:last_name)
  end  
              
  def invited_not_attending
    invitation.invited_members - attending_members
  end
    
  def self.find_or_create_by_hash(key_values)
    method = "find_or_create_by_#{key_values.keys.join("_and_")}"
    self.send(method, *key_values.values)
  end
  
  require 'tzinfo'
  
 
  
  def start_time_local
   return @st ||= (start_time.local_from_utc(time_zone) rescue nil)
  end

  def end_time_local
   return @et ||= (end_time.local_from_utc(time_zone) rescue nil)
  end
  
      
  def short_date
    self.start_time_local.strftime("%b %d") rescue '--'
  end
   
  def expired?
    self.start_time < Time.now.utc
  end 
   
  def undisclosed_address?
    self.invitation.undisclosed_address?
  end
   
  def messages_for_viewer(viewer)
    selected_messages = self.messages.select { |message| (message.author == viewer || message.recipients.include?(viewer)) }
    selected_messages.sort_by { |m| m.created_at }
  end
   
  def messages_for_conversation(viewer, guest)
    selected_messages = self.messages.select do |message| 
      (message.author == viewer && message.recipients.include?(guest)) || (message.author == guest && message.recipients.include?(viewer))
    end
    selected_messages.sort_by { |m| m.created_at }
  end

  def most_recent_message(viewer)
    messages_for_viewer(viewer)[-1] rescue nil
  end

  # force a index update with :re_index => true
  def self.create_future_meetings(invitation, options = {}) 
    return if invitation.deactivated?

    invitation.calc_duration
    duration = invitation.duration  
    self.transaction do
      invitation.future_occurances do |occurance|     	
        meeting =   self.find_or_create_by_hash(:invitation_id => invitation.id,
          :start_time => occurance,
          :end_time => occurance + duration,
          :time_zone => invitation.time_zone)
        meeting.save!  if( meeting.new_record? || options[:re_index]  )
        m = MeetingMember.new
        m.meeting_id = meeting.id
        m.member_id = meeting.invitation.member_id
        m.save
		logger.debug("Creating meeting for #{invitation.id} meeting.id: #{meeting.id}")
      end
    end
  end

  # Just giving some SQL subqueries more instructive names...
  RECURRING = " recurrence_frequency is not NULL AND recurrence_frequency != '' " 
  INVS_LESS_THAN_12_FUTURE_MTGS =  " (SELECT invitation_id from ((SELECT count(*) as count, invitation_id  FROM `meetings` WHERE (start_time > NOW()) group by invitation_id) as meeting_counts) WHERE count < 12) "
  NOT_DELETED = " deactivated != 1 "
  def self.create_all_future_meetings(days_back = 7)
    limit = 30
    offset = 0 
    
    while( invitations = Invitation.find_by_sql("SELECT * from events WHERE #{RECURRING} AND id in #{INVS_LESS_THAN_12_FUTURE_MTGS} AND #{NOT_DELETED} LIMIT #{offset},#{limit}  ") ) do
          break if invitations.blank?
          offset += limit
	  invitations.each do |invitation|
		logger.info("Creating future meetings for #{invitation.id} #{invitation.name}")
		begin
		  create_future_meetings(invitation) 
		  invitation.save!  # This should update the next occurance for the invitation.
		rescue
		  logger.error("ERROR:  Failed to create meetings for #{invitation.id} #{invitation.name} #{$!.message} #{$!.backtrace.join("\n")} ")
		end
	  end
    end
  end      



  def rsvps_for_meeting
    self.confirmations.count
  end
  
  
  def person
   person_description = ''
   person_description << self.invitation.invitee_profile unless self.invitation.invitee_profile.blank?
   self.confirmed_invitees.each do |invitee|
    person_description << invitee.member_profile.to_indexable_string rescue ""
   end
   person_description << self.inviter.member_profile.to_indexable_string rescue ""
   person_description
  end

  
   # Ferret needs these
  def start_time_idx()  return self.start_time.strftime("%Y%m%d%H%M"); end
  def end_time_idx()    return self.end_time.strftime("%Y%m%d%H%M"); end

end
