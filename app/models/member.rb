require 'digest/sha1'

class Member < ActiveRecord::Base

 apply_simple_captcha :message => "Please enter the text exactly as it appears in the box below."

 has_one  :member_profile, :dependent => :destroy
 has_many :account_emails

 has_many :invitations, :dependent => :destroy do
  def future
   find(:all, :conditions => [ "(recurrence_frequency IS NOT NULL AND recurrence_frequency != '') OR start_time >= NOW() and deactivated = 0" ])
  end
  def expired
   find(:all, :conditions => [ "(recurrence_frequency IS NULL OR recurrence_frequency = '') AND start_time < NOW() and deactivated = 0" ])
  end
  def recurring
   find(:all, :conditions => [ "(recurrence_frequency IS NOT NULL AND recurrence_frequency != '') and deactivated = 0 " ])
  end
  def deleted
   find(:all, :conditions => [ " deactivated = 0 " ])
  end
 end

 has_many :meetings, :through => :invitations
 has_many :addresses, :through => :invitations, :order => 'name' 
 has_many :drafts, :dependent => :destroy, :class_name => 'Invitation', :conditions =>  " draft_status = 'draft' "
 has_many :confirmations, :dependent => :destroy
 has_many :invites, :through => :confirmations, :source => :invitation
 has_many :sent_messages, :class_name => 'Message', :foreign_key => 'author_id'
 has_many :member_approvals, :dependent => :destroy
 has_many :invited_to_invitations, :through => :member_approvals, :source => :invitation
 has_many  :confirmed_invites,
  :source => :invitation,
  :through => :confirmations,
  :conditions => ["status_id = 120"]    
 has_one :social_network_user
 has_many :contacts , :dependent => :destroy
 # #has_many  :non_member_contacts, :through => :contacts,  :source =>
 # :contactable
 has_many :flaggings
 has_many :flagged_invites, :through => :flaggings, :source => :invitation
 has_many :saved_searches
 has_many :member_emails
 attr_accessor :new_password
 attr_accessor :terms_of_service
 attr_accessor :do_username_validation
 
  serialize :data


 
 def closed_bubbles
    ((self.data ||= {})[:closed_bubbles] ||= {} )
 end
 
 
 # TODO: These need to be moved to associations... I just can't wrap my brain
 # around it today. -dave
 def member_contacts
  @member_contacts ||= Member.find_by_sql("select members.* from members, contacts where contacts.member_id =  #{self.id} and contacts.contactable_id = members.id and contacts.contactable_type = 'Member' ")
 end
  
 def member_contact_profiles
  MemberProfile.find(:all , :conditions => ["members.id in (?)", member_contacts.map(&:id)], :include => [:member, :picture])
 end
  
 def non_member_contacts
  @non_member_contacts ||= NonMember.find_by_sql("select non_members.*, contacts.name  from non_members, contacts where contacts.member_id =  #{self.id} and contacts.contactable_id = non_members.id and contacts.contactable_type = 'NonMember' ")
 end
  
 def all_contacts
  @all_contacts ||= (member_contacts + non_member_contacts)
 end
  
 def add_contact(contact, name = nil)
  logger.error("Tried to add contact to the same member #{self.id}") and return if(contact == self)
  begin
   self.contacts.create(:contactable => contact, :name => name) unless self.contacts.include?(contact)
  rescue
   logger.error("CONTACT ERROR: error saving contact #{$!.message}")
  end
 end
  
 def add_contacts(contacts, emails_to_names = {})
  Contact.transaction do 
   contacts.each do |contact|
    add_contact(contact, emails_to_names[contact.email])
   end
  end
 end
 def convert_to_contacts(members = nil, non_members = nil)
  members = (past_inviters | past_invitees) if(members.nil?)
  Contact.transaction do 
   members.each do |member|
    self.add_contact(member)
   end
   unless(non_members.nil?)
    non_members.each do |non_member|
     self.add_contact(non_member)
    end
   end
  end
 end
  
 def self.convert_all_to_contacts
  members = Member.find(:all, :include => [:invites ])
  Contact.transaction do 
   members.each do |member|
    begin
     member.convert_to_contacts()
    rescue
     logger.error("Could not convert #{member.id} to contacts because of #{$!.message}")
    end
   end
  end
  members
 end
  
  
 def owner(object)
  method = object.class.name.underscore
  if self.respond_to?(method)
   self.send(method) == object
  elsif self.respond_to?(method.pluralize)
   self.send(method.pluralize).include?(object)
  else
   return false
  end
 end

 def invited_to(invitation)
  return invited_to_invitations.include?(invitation)
 end

 def accepted(meeting)
  return has_invite_in_state(meeting, 'confirmed')
 end 
 alias :was_approved :accepted
  
 def attending(meeting)
  accepted(meeting)
 end

 def declined(meeting)
  return has_invite_in_state(meeting, 'declined')
 end

 def requested_invitation(meeting)
  return has_invite_in_state(meeting, 'accepted')
 end

 def was_rejected(meeting)
  return has_invite_in_state(meeting, 'rejected')
 end

 def is_watching(meeting)
  return has_invite_in_state(meeting, 'saved')
 end 
  
 def can_see_address_details(invitation)
  return (invited_to(invitation) || owner(invitation) || confirmed_invites.include?(invitation))
 end


 def confirmation_for(meeting)
  meeting.confirmations.find_by_member_id(self.id)
 end
  
 @@being_deleted = false
 def self.being_deleted?
  @@being_deleted == true
 end
 
 def destroy
  begin
   @@being_deleted = true 
   super
  ensure
    @@being_deleted = false
  end
 end

  
 # Shows confirmations that are eligible for display in the "Dates You've
 # Already Responded To" box. Note that confirmations that would show up as
 # 'Invited' or 'New' are excluded.
 def confirmations_for(invitation)
  self.confirmations.find(:all, 
   :conditions => ['invitation_id = ? AND status_id != ? AND status_id != ?', invitation.id, Status['approved'].id, Status['new'].id])
 end

 def past_inviters
  self.invites.collect { |i| i.inviter }.compact
 end
  
 def past_invitees
  self.invitations.collect { |i| i.invitees }.flatten.compact.uniq
 end
  
 def fullname
  fn = "#{self.first_name} #{self.last_name}"
  fn = user_name if fn.blank?
  return fn
 end

 def welcome_name
  fn = "#{self.first_name}"
  fn = user_name if fn.blank?
  return fn
 end
  
 def posted_invites(univ,limit = nil)   
  posted_invites = invitations.select{|inv| !inv.start_time.nil? && inv.posted? && (inv.recurring? || inv.start_time > Time.now.utc) && !inv.deactivated?}.sort_by(&:next_occurrence)
  posted_invites = posted_invites[0..limit] if limit
  posted_invites  
 end  

 def posted_invites_public_private(univ,limit = nil)   
  posted_invites = invitations.select{|inv| inv.university_name == univ && !inv.start_time.nil? && inv.posted? && (inv.recurring? || inv.start_time > Time.now.utc) && !inv.deactivated?}.sort_by(&:next_occurrence)
  posted_invites = posted_invites[0..limit] if limit
  posted_invites  
 end  
  
 def public_posted_invites(limit = nil)
  public_invites = invitations.select{|inv| !inv.start_time.nil? && inv.posted? && (inv.recurring? || inv.start_time > Time.now.utc) && !inv.deactivated? && inv.is_public? }
  public_invites = public_invites.sort { |a, b| b.next_occurrence <=> a.next_occurrence }
  public_invites = public_invites[0..limit] if limit
  public_invites
 end

 def public_profile_posted_invites(ac,limit = nil)
  public_invites = invitations.select{|inv| inv.university_name == ac && !inv.start_time.nil? && inv.posted? && (inv.recurring? || inv.start_time > Time.now.utc) && !inv.deactivated? && inv.is_public? }
  public_invites = public_invites.sort { |a, b| b.next_occurrence <=> a.next_occurrence }
  public_invites = public_invites[0..limit] if limit
  public_invites
 end

 def past_posted_invites(university) 
  invitations.select{|invite|   (!invite.start_time.nil? && invite.posted? && (invite.start_time <= Time.now.utc) && !invite.deactivated? && invite.university_name == university) }
 end
         
 def past_attended_meetings(university)
  Meeting.find(:all, :include => [:invitation, :confirmations], 
   :conditions => ["confirmations.status_id = ? and confirmations.member_id = ? and meetings.start_time < ? && events.deactivated != 1 and events.university_name = ?", Status[:confirmed].id, self.id, Time.now.utc,university])
 end
  
 def received_invites(university)
   
  Invitation.find(:all, :select => ' events.* ', 
   :joins => "INNER JOIN member_approvals ON events.id = member_approvals.invitation_id",
   :conditions => [ "((events.recurrence_frequency IS NOT NULL AND events.recurrence_frequency != '') OR events.start_time >= ?) AND member_approvals.member_id = ? AND events.deactivated = 0 AND events.university_name = ?", Time.now.utc, self.id,university],
   :order => 'next_occurrence', 
   :group => 'events.id')                                               
 end
  
 def initialize(attributes = nil)
  super
  @new_password = false
 end   
 

 def verified?
  self.verified == 1
 end
  
 def self.find_non_verified(email)
  find(:first, :conditions => ["email = ? AND verified = 0", email])
 end

 def self.authenticate(email, pass)
  u = find(:first, :conditions => ["email = ? AND verified = 1 AND deleted = 0", email])
  return nil if u.nil?
  u = find(:first, :conditions => ["email = ? AND salted_password = ? AND verified = 1", email, salted_password(u.salt, hashed(pass))])
  #~ if(u && u.last_login_time < (Time.now - 1.day))
   #~ u.update_attributes(:last_login_time => Time.now() )
  #~ end
  
  return u
 end

 def self.authenticate_public(email, pass,university)
  u = find(:first, :conditions => ["email = ? AND verified = 1 AND deleted = 0", email])
  return nil if u.nil?
  u = find(:first, :conditions => ["email = ? AND salted_password = ? AND verified = 1 AND university_name = ?", email, salted_password(u.salt, hashed(pass)),university])
  #~ if(u && u.last_login_time < (Time.now - 1.day))
   #~ u.update_attributes(:last_login_time => Time.now() )
  #~ end
  
  return u
 end

 def self.authenticate_private(email, pass,university)
  u = find(:first, :conditions => ["email = ? AND verified = 1 AND deleted = 0", email])
  return nil if u.nil?
  u = find(:first, :conditions => ["email = ? AND salted_password = ? AND verified = 1 AND university_name = ?", email, salted_password(u.salt, hashed(pass)),university])
  #~ if(u && u.last_login_time < (Time.now - 1.day))
   #~ u.update_attributes(:last_login_time => Time.now() )
  #~ end
  
  return u
  end

 def self.authenticate_public_private_transition(email)
  u = find(:first, :conditions => ["email = ? AND deleted = 0", email])
  #~ u = find(:first, :conditions => ["email = ? AND verified = 1 AND deleted = 0", email])
  return nil if u.nil?
  u = find(:first, :conditions => ["email = ?", email])
  #~ if(u && u.last_login_time < (Time.now - 1.day))
   #~ u.update_attributes(:last_login_time => Time.now() )
  #~ end
  
  return u
 end


 def self.authenticate_by_token(id, token)
  # Allow logins for deleted accounts, but only via this method (and not the
  # regular authenticate call)
  u = find(:first, :conditions => ["id = ? AND security_token = ?", id, token])
  return nil if u.nil? or u.token_expired?
  return nil if false == u.update_expiry
  u
 end

 def token_expired?
  self.security_token and self.token_expiry and (Time.now > self.token_expiry)
 end

 def update_expiry
  write_attribute('token_expiry', [self.token_expiry, Time.at(Time.now.to_i + 600 * 1000)].min)
  write_attribute('authenticated_by_token', true)
  write_attribute("verified", 1)
  update_without_callbacks
 end

 def generate_username
  return "tt#{Member.find(:all).last.id + 1}"
 end
  
 def generate_security_token(hours = nil)
  if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
    (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
   return new_security_token(hours)
  else
   return self.security_token
  end
 end

 def set_delete_after
  hours = MemberSystem::CONFIG[:delayed_delete_days] * 24
  write_attribute('deleted', 1)
  write_attribute('delete_after', Time.at(Time.now.to_i + hours * 60 * 60))

  # Generate and return a token here, so that it expires at the same time that
  # the account deletion takes effect.
  return generate_security_token(hours)
 end

 def change_password(pass, confirm = nil)
  self.password = pass
  self.password_confirmation = confirm.nil? ? pass : confirm
  @new_password = true
 end

 def parent
  self.class.find(parent_id)
 end
  
 def deleted_at
  @deleted_at || Time.now
 end
  
 def deleted_at= value
  @deleted_at = value
 end
 def record_deleted_account
  DeletedAccount.create!(:name => "#{self.first_name} #{self.last_name}", 
   :username => self.user_name, 
   :email => self.email, 
   :deleted_at => deleted_at, 
   :member_id => self.id,
   :num_invites => self.invitations.count,
   :num_confs => self.confirmations.count,
   :source => self.source,
   :length_of_stay => ( (self.deleted_at - (self.created_at || Time.now))/86400))
 end

 def upcoming_and_confirmed(university)
  meetings_confirmed_as_guest = confirmed_as_guest(university)
  meetings_owner = self.meetings.find(:all, :include => :invitation, :conditions => ["meetings.end_time >= ?", Time.now.utc])
  meetings_owner.delete_if{ |m| m.confirmed_invitees.size.zero? or m.invitation.deactivated? }
  upcoming_and_confirmed = (meetings_confirmed_as_guest + meetings_owner).sort{ |a, b| a.start_time <=> b.start_time }
  upcoming_and_confirmed
 end

 def confirmed_posted(university) 
  meetings_owner = self.meetings.find(:all, :include => :invitation, :conditions => ["meetings.end_time >= ? AND events.deactivated != 1 AND events.university_name = ?", Time.now.utc,university])
  meetings_owner.delete_if{ |m| m.confirmed_invitees.size.zero? }
  meetings_owner
 end

 def confirmed_as_guest(university)
  return self.confirmations.find(:all, :include => { :meeting => :invitation }, 
   :conditions => [ 'meetings.end_time > ? AND confirmations.status_id = ? AND events.deactivated = 0 and events.university_name = ?', Time.now.utc, Status['confirmed'].id,university]).collect(&:meeting)
 end
  
 def future_confirmations(status,university)
  # TODO Make sure this does not include old confs (I removed selected_date > ?
  # clause from conditions)
  #~ if university == 'public'
    #~ self.confirmations.find(:all, :include => :meeting,
     #~ :conditions => [ "confirmations.status_id = ? AND meetings.start_time > ?", Status[status].id, Time.now.utc], 
     #~ :select => " confirmations.*, COUNT(meeting) AS num")
  #~ else ## When access by private meetingwave.
    self.confirmations.find(:all, :include => [:meeting,:invitation],
     :conditions => [ "confirmations.status_id = ? AND meetings.start_time > ? and events.university_name = ?", Status[status].id, Time.now.utc,university], 
     :select => " confirmations.*, COUNT(meeting) AS num")
  #~ end
 end
  

  
 # These next three methods were taken from acts_as_authenticated's "remember
 # me" feature.
 def remember_token?
  remember_token_expires_at && Time.now.utc < remember_token_expires_at
 end

 def remember_me
  self.remember_token_expires_at = 2.weeks.from_now.utc
  self.remember_token            = self.class.hashed("#{email}--#{remember_token_expires_at}")
  save_with_validation(false)
 end

 def forget_me
  self.update_attributes(:remember_token_expires_at => nil, :remember_token => nil)
 end
 
 def create_uuid
  self.uuid = UUID.random_create.to_s if(self.uuid.blank?)  # This check is here for the case where we are restoring users from a good DB.
  self.last_login_time = Time.now
 end
  
 def full_cell_phone_number
  prefix = self.cell_phone_prefix.match(/.*\((\d+)\)/)[1]
  return "#{prefix}#{self.cell_phone_number.gsub(/[\-\.\s]/, '')}"
 end
  
 def username
  return self.user_name
 end

 def user_name=(new_user_name)
  self.write_attribute(:user_name, (new_user_name.strip rescue nil))
 end

 def create_member_profile
  if member_profile.nil?
   member_profile = MemberProfile.create(:member_id => read_attribute(:id))
   ProfileWidget.create(:member_profile => member_profile, :widget_partial => 'employment', :row => '1', :col => 'A')
   ProfileWidget.create(:member_profile => member_profile, :widget_partial => 'educations', :row => '1', :col => 'B')
   ProfileWidget.create(:member_profile => member_profile, :widget_partial => 'meeting_interests', :row => '2', :col => 'B')
   ProfileWidget.create(:member_profile => member_profile, :widget_partial => 'personal', :row => '2', :col => 'A')
  end
 end
  
 def has_location?
  return self.member_profile && ( !self.profile_location.blank? )
 end
  
 def profile_location
  self.member_profile.hometown || self.member_profile.birth_place
 end


 def addresses_for_reuse
   address_list = self.addresses.find(:all, :conditions => [ " kind = 'regular' "])
   address_list = address_list.select { |addr| addr.valid? }
   address_list = address_list.uniq_by { |a| a.display_name }
   address_list
 end

 def open_id_user?
	 (not open_id_url.blank?)
 end

 def validate_username?
	(not open_id_user?) or @do_username_validation
 end

 protected

 attr_accessor :password, :password_confirmation

 def validate_password?
  @new_password and not open_id_user? 
 end



 def self.hashed(str)
  return Digest::SHA1.hexdigest("change-me--#{str}--")[0..39]
 end

 after_save '@new_password = false'
 after_validation :crypt_password
 def crypt_password
  if @new_password
   write_attribute("salt", self.class.hashed("salt-#{Time.now}"))
   write_attribute("salted_password", self.class.salted_password(salt, self.class.hashed(@password)))
  end
 end

 def new_security_token(hours = nil)
  write_attribute('security_token', self.class.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
  write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
  update_without_callbacks
  return self.security_token
 end

 def token_lifetime(hours = nil)
  if hours.nil?
   MemberSystem::CONFIG[:security_token_life_hours] * 60 * 60
  else
   hours * 60 * 60
  end
 end

 def self.salted_password(salt, hashed_password)
  hashed(salt + hashed_password)
 end

 def has_invite_in_state(meeting, *states)
  status_ids = states.collect { |s| Status[s].id }
  c = meeting.confirmations.find(:first, :conditions => ['member_id = ? AND status_id in (?)', self.id, status_ids]) if !meeting.nil?
  return (!c.nil?)
 end  

 def not_facebook_user?
  facebook_only = self.password.blank? && self.social_network_user	
  return !facebook_only
 end


 # do_username_validation should be true by default, unless it has been explicitly
 # set to false for this save.
 # This is so that OpenID users can be created initially without a username,
 # then asked for their username on the next step.


 def set_username_validation
	 if @do_username_validation != false
		 @do_username_validation = true
	 end
 end

 before_destroy :record_deleted_account
 #~ before_create :create_uuid
 after_create :create_member_profile
 before_validation :set_username_validation

 validates_presence_of :user_name, :on => :create, :if => :validate_username?
 validates_presence_of :user_name, :if =>  Proc.new { |user| user.open_id_user? and user.validate_username? }
 validates_length_of :user_name, :within => 4..40, :on => :create, :if => :validate_username?
 validates_uniqueness_of :user_name, :if => :validate_username?
 validates_format_of :user_name, :with => /^[\d*\w*\.]+$/, :message => "can contain only word characters.", :if => :validate_username?
 validates_uniqueness_of :email, :if => :not_facebook_user?
 validates_presence_of :email, :message => "Email address should not be blank." , :if => :not_facebook_user?
 validates_format_of :email, :with => RE::VALID_EMAIL, :on => :create, :message => "Please enter a valid email address." ,:if => :not_facebook_user? 
 validates_acceptance_of :terms_of_service
 validates_presence_of :password, :if => :validate_password? 
 validates_confirmation_of :password, :if => :validate_password?, :message => "The passwords don't match."
 validates_length_of :password, { :minimum => 6, :if => :validate_password? }
 validates_length_of :password, { :maximum => 40, :if => :validate_password? }
  

  
end
