require 'facebook_helper'

class SocialNetworkUser < ActiveRecord::Base
 include TTB::FacebookCanvasHelper
 belongs_to :member
 serialize :data          #  This could be a performance issue and initially is used for the flash messages.
 require 'ostruct'
 def self.removed_application(uid)
  self.find_by_uid(uid).removed_application() 
 end
   
 def removed_application
  self.remove_date = Time.now    
  self.blow_away_member
 end
  
 def has_location?
  return ( has_city_state? || has_zip? || has_country?)
 end
  
 def upcoming_invitations(opts = {})
  opts[:limit] ||= self.number_on_profile.to_i
  if(self.has_location? )
   geoip_loc = OpenStruct.new(:city =>  self.city, :state => self.state, :zip => self.zip )
   upcoming_invites = Invitation.find_near_location_facebook(geoip_loc, opts )
  elsif(self.member && self.member.has_location?)
    upcoming_invites = Invitation.find_for_terms_facebook(self.member.profile_location, opts ) 
    geoip_loc = OpenStruct.new(:city => self.member.profile_location)  
  else
   upcoming_invites = geoip_loc = nil
  end
  return upcoming_invites, geoip_loc
 end
   
 def self.ensure_create_user(uid, facebook_user)
  user = nil
  klass =  Facebooker.is_for?(:bebo) ? BeboUser : FacebookUser
  begin   
   user = klass.find_or_initialize_by_uid(uid)
   new_record = user.new_record?
   if(new_record)
    facebook_user.populate(:name) unless facebook_user.instance_variable_get("@name")
    user.name ||= facebook_user.name
    user.save!
   end
  rescue Exception => err
   logger.error("Found exception in creating user: #{err.message}")
   sleep(rand()) # back off for less than a second.
   user = klass.find_or_initialize_by_uid(uid)
   new_record = user.new_record?
   if(new_record)
    facebook_user.populate(:name) unless facebook_user.instance_variable_get("@name")
    user.name ||= facebook_user.name
    user.save
   end
   user = klass.find(uid)
  end
       
  raise "DidntCreateFBuser" unless user
     
  return user     
 end
   
 def init_user!(facebook_session)
   init_user(facebook_session)
   self.save_without_validation
  logger.debug("******** Saved an FB User.")
 end
 
 def init_user(facebook_session)

  facebook_user = facebook_session.user
  facebook_user.populate 
    
  location = facebook_user.current_location
  if( location.nil? || location.city.blank? )
   location = facebook_user.hometown_location
  end

  self.name = facebook_user.name
  [:city,:state,:country,:zip].each do |attribute|
   self.send("#{attribute}=", location.send(attribute).to_s) if(self.send(attribute).blank?)
  end if(location)
    
  self.session_key = facebook_session.session_key
  self.session_expires = facebook_session.instance_variable_get("@expires")
  self.last_access = Time.now
 
 end

 def has_city_state?
  !(city.blank? || state.blank?)
 end

 def has_zip?
  !(zip.blank?)
 end

 def has_country?
  !country.blank?
 end

 def new_user?
  last_access.nil?
 end

 def merged_account?
  self.member 
 end
  
 # A place to store messages for the user when they go to the canvas.
 def flash_message=(message)
  flash[:message] = message
 end

 def flash_error_message=(message)
  flash[:error_message] = message
 end

 def flash_message
  flash[:message]
 end

 def flash_error_message
  flash[:error_message]
 end

 def flash
  data[:flash] ||= Hash.new
 end


 {:include_my_invitations => "false", :include_upcoming_invitations => "true", :number_on_profile => "5", :image_path => ""}.each do |setting, default|
  methods = <<-EOL
      def #{setting}
         if(self.data[:#{setting}].nil?)
            self.data[:#{setting}] =  \"#{default}\"
         end
         self.data[:#{setting}]
      end

      def #{setting}=(value)
         self.data[:#{setting}] = value
      end

      def #{setting}_is_set?
         puts data.to_yaml
         self.data.has_key?(:#{setting})
      end

  EOL

  module_eval(methods)

 end

 def pages
  data[:pages] ||= Hash.new
 end

 def set_page_settings(page_id, settings)
  pages[page_id] = settings
 end


 def data
  unless(super)
   self.data = Hash.new
  end
  return super
 end

 def setup_profile?
  self.has_location?
 end

 def has_flash_message?
  data[:flash] && (data[:flash][:message ] || data[:flash][:error_message]  )
 end

 def clear_flash_messages
  if(data[:flash])
   data[:flash].delete(:message)
   data[:flash].delete(:message)
  end
 end

 def get_facebook_user
  return @fb_user if @fb_user
  @fb_user =   create_session.user
  @fb_user.populate
  @fb_user
 end
  
 def blow_away_member
  return unless( self.email.blank? and self.member.invitations.blank? and self.member.confirmations.blank?) 
  SocialNetworkUser.transaction do     
   self.member.deleted_at = self.remove_date || Time.now
   self.member.destroy if(self.member)
   self.member = nil
   self.save_without_validation
  end
 end

 def removed_app?
  self.remove_date && ( self.remove_date > (self.last_access || Time.at(0)) )
 end
 
 def after_initialize
   @more_than_one_day_old = ( self.last_access || Time.now) < (Time.now - 1.days)
 end
 
 def before_save
  if(@more_than_one_day_old)
   self.offline_access = self.offline_access?
   self.email_access = self.email_access?   
  end
  return true
 end
  
 def after_save
  unless(self.merged_account? || removed_app?)
   begin
    parts = self.name.split
    base_user_name = (parts.first + parts.last[0..0]).downcase
   rescue
    base_user_name = "facebook_user"
   end

   all_users_with_similar_name = Member.find(:all, :conditions => ["user_name like ?", "#{base_user_name}%"])
   index = 1
   user_name = base_user_name
   while(all_users_with_similar_name.detect{|u| u.user_name == user_name})
    user_name = base_user_name + ( index += 1).to_s
   end

   member = Member.new(:user_name => user_name, :first_name => "", :last_name => "", :source => "facebook")

   member.save_without_validation

   self.member = member
   self.update_attribute(:member_id, member.id)
  end
 end

 def notify_post_invite(invitation)
  self.flash_message = "Your invitation has been successfully posted!  Notifications have been sent to your invitees to let them know about this invite."
  unless(invitation.closed?)
   begin
    klass = (Facebooker.is_for?(:facebook)) ? FacebookerFeedPublisher: FacebookPublisher
    klass.deliver_post_invite(create_session.user, invitation)
   rescue Exception => err
    logger.error("Error sending publish story action. #{err.message}")
    raise err unless(RAILS_ENV == 'production')
   end
  end
 end       

 def notify_confirmation(confirmation)    
  invitation = confirmation.invitation
  if( invitation.is_public?  && (confirmation.attending? || confirmation.wants_to_attend?) )
   begin
    klass = (Facebooker.is_for?(:facebook)) ? FacebookerFeedPublisher: FacebookPublisher
    klass.deliver_confirmation(create_session.user, confirmation)
   rescue
    logger.error("Error sending publish story action. #{$!.message}")
    raise $! unless RAILS_ENV == "production"
   end
  end
 end
 def pass_email(part)
  begin
   body = part.body  
   FacebookPublisher.deliver_notification([self.uid],self.create_session.user,  body) 
  rescue
   
   logger.error("***************Tried to send email to FB user #{self.name} but there was no body. #{$!.backtrace.join("\n")}")
  end
 end
  
 def has_profile_settings?
  !(city.blank? and state.blank? and country.blank? and zip.blank? and data.blank?)
 end

 def offline_push_profile
  # FacebookPublisher.deliver_profile_for_user(self.create_session.user, self,
  # nil)
  begin
   if( self.has_profile_settings? )
    app = ActionController::Integration::Session.new;
    app.get "facebook/get_profile_fbml/#{self.id}"

    if(app.response.code.to_i == 200 )
     fbml = app.response.body.gsub("www.example.com", "www.meetingwave.com")
     session = Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
     session.secure_with!(self.session_key,self.uid,0)
     session.user.profile_fbml = fbml
    else
     logger.error("FB:: FBML PUSH :: Couldn't push fbml due to some error in the building. ")
    end
   elsif( ENV["RESET_DEFAULT_PROFILE"] )
    create_session.user.profile_fbml = "<fb:ref url='http://www.meetingwave.com/social_network/default_profile' />"
   end
  rescue
   logger.error("FB:: FBML PUSH :: #{$!.message} #{$!.backtrace.join("\n")} ")
  end
 end

 def get_profile_fbml
  begin
   app = ActionController::Integration::Session.new;
   app.get "facebook/get_profile_fbml/#{self.id}"

   if(app.response.code.to_i == 200 )
    fbml = app.response.body.gsub("www.example.com", "www.meetingwave.com")
    session = Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    session.secure_with!(self.session_key,self.uid,0)
    session.user.profile_fbml = fbml
   else
    logger.error("FB:: FBML PUSH :: Couldn't push fbml due to some error in the building. ")
   end
  rescue
   logger.error("FB:: FBML PUSH :: #{$!.message} #{$!.backtrace.join("\n")} ")
  end
 end

 def push_profile_for_pages

  self.pages.keys.each do |page_id|
   begin
    app = ActionController::Integration::Session.new;
    app.get "facebook/get_profile_fbml/#{self.id}?facebook_page_id=#{page_id}"

    if(app.response.code.to_i == 200 )
     fbml = app.response.body.gsub("www.example.com", "www.meetingwave.com")
     session = create_session
     user = Facebooker::User.new(page_id)
     user.session = session
     user.profile_fbml = fbml
    else
     logger.error("FB:: FBML PUSH :: Couldn't push fbml due to some error in the building. ")
    end
   rescue
    logger.error("FB:: FBML PUSH :: #{$!.message} #{$!.backtrace.join("\n")} ")
   end
  end
 end
 
 
 def offline_access?
  get_perms["offline_access"].to_i == 1
 end
 
 def email_access?
  get_perms["email"].to_i == 1
 end
 
 def get_perms
  
  return @perms if @perms
  @perms =   self.create_session.fql_query("select email,offline_access from permissions where uid = (#{self.uid})").first rescue {}
  return @perms
  
 end
 
 def self.push_notification(only_us = true, content = nil)
  require 'application_controller.rb'
  
  unless(content)
  file = ENV["NOTIFY_FILE"] || ""
    
  raise "NOENV[NOTIFY_FILE]" unless File.exists?(file)
    
  content = File.open(file).read()
  end
    
  #   puts "Pushing content to #{only_us ? "Only Us" : "Every One" } #{content}"
    
  conditions = only_us ? 'name = "David Clements" or name = "Doug Fales" or name = "John Boyd" or name = "Andrew Williams"' : "session_key is not NULL"
  #conditions = only_us ? 'name = "Sandy Dux"' : "session_key is not NULL"
  limit = 200
    
  offset = 0 
  if(ENV["OFFSET"])
   offset = ENV["OFFSET"].to_i
  end
    
  @errors = []   
  while( recipients = SocialNetworkUser.find(:all, :conditions => conditions, :limit => limit , :offset => offset )) do
   break if(recipients.blank?)
   puts "Sending for #{limit} more at #{offset}"
   offset += limit
   
   FacebookPublisher.deliver_base_notification(recipients.map(&:uid).compact, recipients.first.create_session.user, content.gsub(/<.?p>/,"").gsub(/<p.*?>/, ""))

  end
 end
  
 def self.push_emails(subject, text, html, only_us = true)
  conditions = only_us ? 'name = "David Clements" or name = "Doug Fales" or name = "John Boyd" or name = "Andrew Williams"' : "session_key is not NULL"
  
  limit = 100
  offset = 0 

  dave = SocialNetworkUser.find_by_uid(830904376)
  dave = dave.create_session.user
  while( recipients = SocialNetworkUser.find(:all, :conditions => conditions, :limit => limit , :offset => offset )) do
   break if(recipients.blank?)
   logger.debug "Sending for #{limit} more at #{offset}"
   offset += limit
       
   FacebookPublisher.deliver_adhoc_email(dave,recipients.map(&:uid), subject , html, text)     
  end
   
 end


 def create_session
  unless(@facebook_session)
   Facebooker.load_adapter(:config_key_base => ( BeboUser === self ) ? "bebo" : "")
   klass =  Facebooker::CanvasSession
      
   @facebook_session = klass.create(klass.api_key, klass.secret_key)
   @facebook_session.secure_with!(self.session_key,self.uid,self.session_expires) 
   @facebook_session.user.uid = self.uid
  end
    

  @facebook_session
 end
 
 def set_session(session)
  @facebook_session = session
 end

  
 # ### Stuff for importing profile
 def educations
  return @educations if @educations
  @educations = [] 
  self.create_session.user.populate
   
  get_facebook_user.education_history.each_with_index do |education, index|
   end_year  = education.year unless(education.year.blank?)
   start_year = nil
   if(end_year)
    end_year = Float(end_year).to_i rescue nil
    end_year = nil if end_year < 1800
    start_year = end_year - 4 if(end_year)
   end
   @educations << Education.new(:school_name => education.name, :start_year => start_year,:end_year => end_year, :school_type => Education::COLLEGE)
  end
    
  return @educations
 end
  
 def jobs
  return @jobs if @jobs
  @jobs = []
  get_facebook_user.work_history.each_with_index do |work, index|
   job = Job.new
   job.start_year = ( Date.parse(work.start_date).year rescue nil ) unless work.start_date.blank?

   job.end_year= ( Date.parse(work.end_date).year rescue nil ) unless work.end_date.blank?
   job.title = work.position.to_s.blank? ? work.description.to_s : work.position.to_s
   job.title = work.company_name if(job.title.blank?)
   job.location = work.location.to_s if work.location
   job.employer_name = work.company_name
              
   @jobs << job
  end
  return @jobs
 end
  
 def personal_attr_map(personal_attr)
  case personal_attr.to_s
  when "birthdate"
   :birthday
  when "birth_place"
   :hometown_location
  when "marital_status"
   :relationship_status
  when "political_party_name"
   :political
  when "religion"
   :religion
  when "hometown"
   :current_location
  when "from_country"
   ( get_facebook_user.current_location.country.blank? ? get_facebook_user.hometown_location.country : get_facebook_user.current_location.country )
      
  else
   nil
  end
 end
  
 MemberProfile::ATTRS_BY_TYPE[:personal].each do |personal_attr|
  define_method(personal_attr) do
   fb_attr = personal_attr_map(personal_attr)
   if(fb_attr)
    if(Symbol === fb_attr)
     get_facebook_user.send(fb_attr).to_s
    else
     fb_attr
    end
   else 
    nil
   end
       
  end
 end
  

end
