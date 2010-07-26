require 'scheduled'

class Invitation < Event
  MAX_MEETINGS = 200

 
  include ActionView::Helpers::TextHelper
  include ChangedAttributes		
  include TTB::Scheduled
 
  acts_as_rateable  
	
  SORTED_ATTRS_FOR_CHANGE_NOTE = ["name", "description", "start_time", "end_time", "time_zone", "activity_id", "payment_id", "purpose_id", "address_id",	"minimum_invitees", "maximum_invitees", "open"]
	
  IGNORE_ATTRS = [ 'created_at', 'updated_at', 'member_id', 'step', 'new_record', 'class', 'draft_status', 'id', 'open']

  USER_FACING_NAMES = { :payment_id => 'Cost' }
	
  # Invitees validation
  MAX_EMAILS = 10
  OVER_MAX_EMAIL_LIMIT_MESSAGE = "You can only invite 10 non-members at a time."
  INVALID_EMAIL_MESSAGE				 = "The following were not valid email addresses: %s."

  POSTED = 'posted' 
  DRAFT = 'draft'
	
  # For QuickInvite
  WHO_EXAMPLE = 'e.g. johnboyd, jack@example.com, ...'
  WHERE_EXAMPLE = 'e.g. Starbucks, 33rd & 5th, New York, NY'
  WHAT_EXAMPLE = 'e.g. Coffee Talk'
  WHY_EXAMPLE = 'e.g. Networking'
  
  # Associations.	 PLEASE prune these as they become obsolete.	
  belongs_to :inviter, :class_name => 'Member', :foreign_key => 'member_id'
  belongs_to :address
  belongs_to :purpose
  belongs_to :activity
  belongs_to :payment
  has_one :hidden_user_name
  has_many	 :confirmations, :dependent => :destroy
  has_many	 :non_members, :dependent => :destroy
  has_many	 :members, :through => :confirmations, :order => 'last_name'
  has_many	 :member_approvals, :dependent => :destroy
  has_many	 :invited_members, :through => :member_approvals, :source => :member
  has_many	 :invited_and_notified_members, :through => :member_approvals, :source => :member, :conditions => [ 'member_approvals.notified = 1']
  has_many	 :invited_and_unnotified_members, :through => :member_approvals, :source => :member, :conditions => [ 'member_approvals.notified != 1' ]
  has_many	 :non_member_approvals, :dependent => :destroy
  has_many	 :invited_non_members_assoc, :through => :non_member_approvals, :source => :non_member
  has_many	 :invited_and_notified_non_members, :through => :non_member_approvals, :source => :non_member, :conditions => [ 'notified = 1']
  has_many	 :invited_and_unnotified_non_members, :through => :non_member_approvals, :source => :non_member, :conditions => [ 'notified != 1']
  has_many	:invitees, # Collects members for all confirmations except 'saved'
  :through => :confirmations,
    :source =>	:member,
    :conditions => ["status_id != 100"], 
    :order => 'last_name'
  has_many	:confirmed_invitees,
    :source => :member,
    :through => :confirmations,
    :conditions => ["status_id = 120"],
    :order => 'last_name', :group => 'member_id'
  has_many	:declined_invitees,
    :source => :member,
    :through => :confirmations,
    :conditions => ["status_id = 119"],
    :order => 'last_name', :group => 'member_id'
  has_many	:confs_confirmed,
    :class_name => 'Confirmation',
    :source => :confirmations,
    :conditions => ["status_id = 120"]
  has_many	:confs_accepted,
    :class_name => 'Confirmation',
    :source => :confirmations,
    :conditions => ["status_id = ? ", Status['accepted'].id]
  has_many :meetings , :dependent => :destroy
  has_many :messages
  has_many :reminders, :dependent => :destroy

  has_many :flaggings
  has_many :flagging_members, :through => :flaggings, :source => :member
	
  
  define_index do
    #~ # fields
    indexes :id, :sortable => true
    has activity_id
    has purpose_id  
    indexes :name
    indexes description
    indexes preference_flag
    indexes virtual_flag
    indexes virtual_f
    indexes university_name
    indexes draft_status
    has no_pref
    has is_public
    has deactivated
    indexes address.city
    indexes address.state
    indexes address.country 
    indexes address.zip
    indexes address.airport_id
    has address.zip_code_id
    #~ has "address.id",:as => :add_id
    #~ has "CAST(address.id)", :type => :integer
    indexes inviter.first_name
    indexes inviter.last_name
    indexes inviter.user_name
    # attributes
    has meetings.start_time, :as => :start_date, :sortable => true
    has meetings.end_time, :as => :end_date
    set_property :delta => true

  end
  
	
  attr_accessor :viewer
  def invited_non_members
   contacts = self.inviter.non_member_contacts.group_by(&:email)
   non_members = invited_non_members_assoc
   non_members.each do |non_member|
     non_member["name"] = ( contacts[non_member.email].first.name rescue nil )
   end
   non_members
  end
  def self.copy(attributes)
    new(attributes.delete_if {|k,v| ['recurrence_frequency', 'start_time', 'end_time', 'draft_status','created_at'].include?(k) } )
  end

  def all_invited_members() return (invited_members + invited_non_members); end
	
  def current_confs_accepted
    self.confs_accepted.delete_if{ |conf| conf.meeting.expired? rescue true}
  end

  def future_meetings
    meetings.select{|m| m.start_time >= Time.now.utc if m.start_time} 
  end		
	
  def past_meetings 
    meetings.select{|m| m.start_time < Time.now.utc if m.start_time} 
  end 
        
  # This allow for the name of the invite to be in the URL. Google like that alot.
  def to_param
    "#{self.id}-#{name.gsub(/[^a-z0-9]+/i, '-')[0..50]  rescue "" }"
  end
	
  def destroy
    if(self.recurring? && past_meetings.length > 0 && !Member.being_deleted? )	 
      # We don't delete invitation that have past occurances. We mark it as deactivated and delete all future meetings
      self.deactivated = true
      self.future_meetings.map(&:destroy	)
      # We don't want this to fail because of some validation constraint we add later in the project.
      self.save_with_validation false  
    else
      super
    end 
  end
	
  def deactivated?
    self.deactivated
  end	

  def flag!
    update_attribute(:flagged, true)
  end

  def clear_flags!
    update_attribute(:flagged, false)
    flaggings.each { |f| f.destroy }
  end
		
  def guest_responses(viewer, meeting) 
    res = []
    if self.inviter == viewer
      res << invited_members    
      res << meeting.people_requested_invites	
      res << invited_non_members    
    elsif meeting
      res << meeting.confirmed_invitees
    else
      # This should not occur.  This method should always take a meeting.
      logger.error("Invitation#guest_responses called without a meeting!!!! Returning an empty array.")
      return []
    end
    return res.flatten.uniq
  end			

  def self.invite_return(search_filter)
    if !search_filter.zip.blank? ||  !search_filter.city.blank?
      r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",search_filter.zip,search_filter.city])
      rad = 50
      if !r.nil?
        sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
        z = ZipCode.find_by_sql(sql)
        zcids = z.collect(&:id)
      end
    else
      zcids = ""
    end
    zcids = "" if r.nil?
    
    @invitations = Invitation.search "#{search_filter.terms} #{search_filter.country}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19},:conditions => {:university_name => 'public'}, :order => :start_date, :sort_mode => :desc
    return @invitations
  end

  def guest_responses_for_inviter(meeting) 
    guest_list = []
    outstanding_rsvps = []
    if meeting
      guest_list.concat(invited_members)
      guest_list.concat(invited_non_members)
      guest_list.concat(meeting.people_declined)
      guest_list.concat(meeting.attending_members)
      guest_list.uniq!
      outstanding_rsvps.concat(meeting.people_requesting_invites)
    else
      # This should not occur.  This method should always take a meeting.
      logger.error("Invitation#guest_responses called without a meeting!!!! Returning an empty array.")
      return [ [],[] ]
    end
    return [ guest_list, outstanding_rsvps ]
  end				 

  def posted?
    self.draft_status == POSTED
  end	 
	
  def draft?
    self.draft_status == DRAFT
  end   
	
  def mark_posted
    self.draft_status = POSTED
  end
	
  def mark_draft
    self.draft_status = DRAFT
  end
	
  def status(*viewer)
    if self.active?
      status = Status[:active]
      viewer = viewer.flatten.first
      if self.members.include?(viewer)
        status = self.confirmations.detect {|c| c.member == viewer }.status
      end
    else
      status = Status[:expired]
    end
    status
  end
	
  def has_invitees?
    (!invited_members.size.zero? or !invited_non_members.size.zero? ) 
  end

  def active?
    return true if(self.start_time.nil? or self.recurring?)
    self.start_time >= Time.now.utc
  end

  def expired?
    !active?
  end
 
  def eligible_invitees_options
    eligible = eligible_invitees 
    eligible.sort! { |a, b| a.user_name.downcase <=> b.user_name.downcase }
    eligible.collect { |m| [m.user_name, m.id.to_s] }
  end

  def eligible_invitees
    self.inviter.member_contacts
    #(self.inviter.past_inviters | self.inviter.past_invitees).compact
  end
  
  
  def notify_invitees
    InvitationNotify.deliver_inviter_destroyed(self) unless self.invitees.blank?
  end

  def upcoming_meeting(after = Time.now.utc)
   
    meeting = get_next_or_only_meeting(after)

    meeting = ensure_meeting(after) unless meeting  # this is generally helpful in dev and staging envs where meetings are getting created.  It could happen in production as well.. so this will help
    #throw "NoUpcomingMeeting#{self.id}" unless meeting   
    meeting.invitation = self  if meeting# Hack in order to reduce calls to lookup the invitation when it isn't associated in this instance.
    if meeting
      return meeting
    else 
      return nil
    end  
  end
  
  def ensure_meeting(after)
    if(self.recurring? )
      Meeting.create_future_meetings(self)
    else
      self.meetings.create(:start_time => self.start_time, :end_time => self.end_time, :time_zone => self.time_zone)
    end
    self.reload    
    get_next_or_only_meeting(after)
  end
  
  def get_next_or_only_meeting(after)   
    if(self.recurring?)  
      meeting = meetings.sort{|x,y| x.start_time <=> y.start_time}.detect{|meeting| meeting.start_time >= after}
    else
      meeting = self.meetings.first
    end 
    meeting
  end

  def most_recent_meeting 
    meetings.sort{|x,y| x.start_time <=> y.start_time}.last	 
    #meetings.find(:first, :order => ["start_time DESC"])		
  end

  def activity_name
    self.activity.name rescue ''
  end   
	
  # def undisclosed_address?
  # 	 self.address.undisclosed?
  # end   
	
  def address_name()	
    unless self.address.conference.blank?
      return self.address.conference;
    else
      return self.address.name; 
    end
  end


  def stars
    if admin_rating > 0
      return admin_rating.to_s
    else
      return "0"
    end
  end

  def city()       return self.address.city; end
  def state()      return State::unabbreviate(self.address.state); end
  def country()    return self.address.country; end
  def zip()        return self.address.zip; end
  def lat()        return (self.address.zip_code.latitude) rescue nil; end
  def lon()        return (self.address.zip_code.longitude) rescue nil; end
  def airport_id() return (self.address.airport_id) rescue nil; end
  def category()   return self.purpose.category rescue nil; end
  def city_alias_names
    self.address.city_alias_names.join(" ") rescue ""
  end
  
  def city_state_for_title

    parts = []
    begin
    parts << city if city
    parts << self.address.state if self.address.state
    parts << country if country && parts.length < 2  
    rescue
    end
    parts.join(", ")
  end

  def private
    return (self.closed? ? "true" : "false")
  end
	
  def recurring
    return self.recurring?.to_s
  end

  def description=(desc)
    write_attribute("description", clean_text(desc))
  end

  def name=(n)
    write_attribute("name", clean_text(n))
  end
	
  def clean_text(txt)
    return (txt.nil? ? nil : txt.strip_tags)
  end

  def short_date
    st = self.upcoming_meeting(Time.now.utc).start_time_local rescue nil
    st.strftime("%b %d") rescue '--'
  end                   
  
  # We record date errors on :base instead of on the invidivual fields.  
  def date_errors?
    return (self.errors.on(:base) == EMPTY_TIME_DATE_MESSAGE)
  end                                                           

  attr_accessor :near_location_hash

  def self.find_near_location(geoip_loc, opts = { :limit => 5 })
    sf = SearchFilter.new(:city => geoip_loc.city, 
      :state => geoip_loc.state, 
      :zip => geoip_loc.zip,
      :start_date => Time.now,
      :radius => 50)
      
      if !sf.city.nil? && !sf.city.blank? && !sf.zip.nil? && !sf.zip.blank?
        r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",sf.zip,sf.city])
        rad = 50
        if !r.nil?
          sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
          z = ZipCode.find_by_sql(sql)
          zcids = z.collect(&:id)
        end
      else
        zcids = ""
      end
      zcids = "" if r.nil?			
      res = Invitation.search "#{sf.state}",:with => {:start_date => Time.now..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10
    #sf.full_text_search(opts )
		  return res
  end 
    
  def self.find_near_location_facebook(geoip_loc, opts = { :limit => 5 })
    sf = SearchFilter.new(:city => geoip_loc.city, 
      :state => geoip_loc.state, 
      :zip => geoip_loc.zip,
      :start_date => Time.now,
      :radius => 50)
      
      if !sf.city.nil? && !sf.city.blank? && !sf.zip.nil? && !sf.zip.blank?
        r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",sf.zip,sf.city])
        rad = 50
        if !r.nil?
          sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
          z = ZipCode.find_by_sql(sql)
          zcids = z.collect(&:id)
        end
      else
        zcids = ""
      end
      zcids = "" if r.nil?			
      res = Invitation.search "#{sf.state}",:with => {:start_date => Time.now..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19}, :order => :start_date, :sort_mode => :desc    #, :page => params[:page], :per_page => 10
    #sf.full_text_search(opts )
		  return res
  end 
        
  def self.find_for_terms(terms, opts = { :limit => 5 })
    sf = SearchFilter.get_for_terms(terms, :start_date => Time.now,:radius => 50)
    sf.full_text_search( opts )
  end
  
  def self.find_for_terms_facebook(terms, opts = { :limit => 5 })
    sf = SearchFilter.get_for_terms(terms, :start_date => Time.now,:radius => 50)
    
    if !sf.city.nil? && !sf.city.blank? && !sf.zip.nil? && !sf.zip.blank?
      r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["zip = ? or city = ?",sf.zip,sf.city])
      rad = 50
      if !r.nil?
        sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
        z = ZipCode.find_by_sql(sql)
        zcids = z.collect(&:id)
      end
    else
      zcids = ""
    end
    zcids = "" if r.nil?			
    res = Invitation.search "#{sf.state}",:with => {:start_date => Time.now..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19}, :order => :start_date, :sort_mode => :desc    #, :page => params[:page], :per_page => 10
	  return res
  end  
	
  def self.home_page_invites(opts = { :limit => 12, :stars => 5} )
  
  
    self.find(:all, 
              :conditions => [ "events.is_public = 1 AND draft_status = 'posted' AND meetings.start_time >= ? AND deactivated = 0 and purpose_id != ? and events.admin_rating = ?", Time.now.utc, Purpose::ROMANCE.id, opts[:stars] ], 
              :order => 'meetings.start_time', 
              :limit => opts[:limit], 
              :include => [:meetings, :address, {:inviter => {:member_profile => :picture }}])
  end

   def self.home_page_invites_in_timeframe(opts = { :limit => 12, :stars => 5, :starting => Time.now.utc, :ending => (Time.now + 24.hours).utc } )
      self.find(:all,
                   :conditions => [ "events.is_public = 1 AND draft_status = 'posted' AND meetings.start_time >= ? AND meetings.start_time <= ? AND deactivated = 0 and purpose_id != ? and events.admin_rating = ? ", opts[:starting], opts[:ending], Purpose::ROMANCE.id, opts[:stars]],
                   :order => 'meetings.start_time',
                   :limit => opts[:limit],
                   :include => [:meetings, :address, {:inviter => {:member_profile => :picture }}])
       end
   
   def self.home_page_invites_in_timeframe1(opts = { :limit => 12, :stars => 5, :starting => (Time.now + 24.hours).utc, :ending => (Time.now + 48.hours).utc, :ids => ids } )
      self.find(:all,
                   :conditions => [ "events.is_public = 1 AND draft_status = 'posted' AND meetings.start_time >= ? AND meetings.start_time <= ? AND deactivated = 0 and purpose_id != ? and events.admin_rating = ? and events.id NOT IN (?)", opts[:starting], opts[:ending], Purpose::ROMANCE.id, opts[:stars],opts[:ids]],
                   :order => 'meetings.start_time',
                   :limit => opts[:limit],
                   :include => [:meetings, :address, {:inviter => {:member_profile => :picture }}])
   end
            
   ## New method for private label today's meetings on home page.            
   def self.home_page_invites_in_timeframe_private_label(opts = { :limit => 12, :stars => 5, :starting => Time.now.utc, :ending => (Time.now + 24.hours).utc,:univ_name => univ_name } )
      self.find(:all,
                   :conditions => [ "events.is_public = 1 AND draft_status = 'posted' AND meetings.start_time >= ? AND meetings.start_time <= ? AND deactivated = 0 and purpose_id != ? and events.university_name = ?", opts[:starting], opts[:ending], Purpose::ROMANCE.id, opts[:univ_name]],
                   :order => 'meetings.start_time',
                   :limit => opts[:limit],
                   :include => [:meetings])
   end
   
   ## New method for private label tomorrow's meetings on home page.            
   def self.home_page_invites_in_timeframe1_private_label(opts = { :limit => 12, :stars => 5, :starting => (Time.now + 24.hours).utc, :ending => (Time.now + 48.hours).utc, :ids => ids,:univ_name => univ_name } )
      #~ and events.admin_rating = ? 
      self.find(:all,
                   :conditions => [ "events.is_public = 1 AND draft_status = 'posted' AND meetings.start_time >= ? AND meetings.start_time <= ? AND deactivated = 0 and purpose_id != ? and events.id NOT IN (?) and events.university_name = ?", opts[:starting], opts[:ending], Purpose::ROMANCE.id,opts[:ids], opts[:univ_name]],
                   :order => 'meetings.start_time',
                   :limit => opts[:limit],
                   :include => [:meetings])
    end                 

   def self.home_page_invites_in_timeframe2(opts = { :limit => 12, :stars => 5, :starting => (Time.now + 24.hours).utc, :ending => (Time.now + 48.hours).utc} )
      self.find(:all,
                   :conditions => [ "events.is_public = 1 AND draft_status = 'posted' AND meetings.start_time >= ? AND meetings.start_time <= ? AND deactivated = 0 and purpose_id != ? and events.admin_rating = ?", opts[:starting], opts[:ending], Purpose::ROMANCE.id, opts[:stars]],
                   :order => 'meetings.start_time',
                   :limit => opts[:limit],
                   :include => [:meetings, :address, {:inviter => {:member_profile => :picture }}])
    end

  # There are still issues with this query... The main thing is the number of meetings that are gettings returned... When all we need is the upcoming meeting.
  def self.find_for_map(limit, opts = { :stars => 1 })
    ids = self.find(:all, 
      :select => "DISTINCT events.id", 
      :conditions => [ "events.is_public = 1 AND draft_status = 'posted'  AND deactivated = 0 AND events.admin_rating >= ? ", opts[:stars]], 
      :limit => limit,
      :joins => [{:address => :geocode}], :order => 'events.next_occurrence desc' ).map(&:id)
    
    load_for_map(ids)
  end 
  
  def self.load_for_map(ids, stars = nil)
    ids = ids.sort.uniq
    logger.debug("Calling load for map.  with #{ids.join(",")}")
    if stars.nil?
      conditions = [ "events.id in (?) and meetings.start_time >= events.next_occurrence", ids] 
    else
      conditions = [ "events.id in (?) and meetings.start_time >= events.next_occurrence and events.admin_rating >= ? ", ids, stars] 
    end
    self.find(:all, :conditions => conditions,
              :include => [:meetings, {:address => [:zip_code, :geocode]}, {:inviter => :member_profile}, :purpose])   
  end

  def self.browse(geoip_loc, category, timeframe, opts = { :limit => 30 })
    sf = SearchFilter.new(:city => geoip_loc.city, 
      :state => geoip_loc.state, 
      :zip => geoip_loc.zip,
      :radius => 50,
      :start_date => Time.now)
    invitations = sf.full_text_search(opts)
    invitations		 
  end
  

  def blank?
    result = true
    attributes.each do |key, val|
      result &= val.blank?	unless IGNORE_ATTRS.include?(key)
    end
    result &= self.invited_non_members.blank?
    result &= self.invited_members.blank?
    result
  end
  def for_romance?
    self.purpose == Purpose::ROMANCE
  end
  def is_public?
    return self.is_public
  end
	
  def is_private?
    return !self.is_public?
  end

  def open?
    return self.is_public?
  end
	
  alias :is_private :is_private?
  alias :closed? :is_private?
  alias :open? :is_public?

  # As of Rails 2.0, we started getting empty strings in the database for recurrence frequency on invitation posts and updates.
  def recurrence_frequency=(new_rec_freq)
    new_rec_freq = nil if new_rec_freq.blank?
    write_attribute(:recurrence_frequency, new_rec_freq)
    new_rec_freq
  end
  def person
   person_description = ''
   person_description << self.invitee_profile unless self.invitee_profile.blank?
   self.confirmed_invitees.each do |invitee|
    person_description << invitee.member_profile.to_indexable_string rescue ""
   end
   person_description << self.inviter.member_profile.to_indexable_string rescue ""
   person_description
  end
	
   # Hack so that meetings and invitations can be handled the same
   def invitation
    return self
   end
   
    # Ferret needs these 
  Invitation::MAX_MEETINGS.times do |time|
     method_name = "start_time_idx" + ( ( time == 0) ? "" : "_#{time + 1}" )
     define_method( method_name ) do 
         return self.meetings[time].start_time_idx() rescue "0"
     end
     
     method_name = "end_time_idx" + ( ( time == 0) ? "" : "_#{time + 1}" )
     define_method( method_name ) do 
         return self.meetings[time].end_time_idx() rescue "0"
     end
  end
  
  def next_occurrence_idx
   self.next_occurrence.strftime("%Y%m%d%H%M")
  end

  protected
  validates_length_of		:name, :in => 3..100
  validates_presence_of :purpose_id
  validates_presence_of :activity_id, :message => "Please select meeting type."
  validates_presence_of :payment_id
  #validates_presence_of :address
  validates_associated	:address, :message => "could not be saved (see errors below)."
  validates_length_of :description, :maximum => 1000
  validates_numericality_of :minimum_invitees, :allow_nil => true
  validates_numericality_of :maximum_invitees, :allow_nil => true
	
  validates_associated :invited_non_members, :message => " Some of the email address(es) you entered are invalid."
  validates_associated :invited_members

	
	
  def validate
    return validate_min_max
  end
 
  def validate_min_max
    min, max = self.minimum_invitees, self.maximum_invitees
    errors.add(:minimum_invitees, "must be a positive integer other than 0. Or you can leave it blank.") unless non_zero_positive_integer?(min)
    errors.add(:maximum_invitees, "must be a positive integer other than 0. Or you can leave it blank.") unless non_zero_positive_integer?(max)
    if errors.on(:maximum_invitees) or errors.on(:minimum_invitees)
      return false
    elsif !min.blank? and !max.blank? and min > max
      errors.add(:maximum_invitees, "cannot be less than the minimum number of invitees.")
      return false
    else
      return true
    end
  end

	
  def non_zero_positive_integer?(n)
    return true if n.blank? # To allow for empty values
    return (n.integer? and n.nonzero? and n.abs == n)
  end
  
 
 

end
