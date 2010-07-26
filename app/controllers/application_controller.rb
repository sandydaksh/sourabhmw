# Filters added to this controller will be run for all controllers in the
# application. Likewise, all the methods added will be available for all
# controllers.
require 'localization'
require 'member_system'
require_dependency 'facebook_ext.rb'   
require 'enumerator'
require_dependency 'metro_areas'
require 'ostruct'
class ApplicationController < ActionController::Base
 cache_sweeper :invitations_sweeper, :members_sweeper, :pictures_sweeper
 include MetroAreas
 include ReCaptcha::AppHelper
 include Localization
 include MemberSystem
 include TTB::FacebookUrlOveride
   
 helper :member
 before_filter :try_set_facebook_session
  
 before_filter :login_from_cookie
 before_filter :set_viewer
 before_filter :set_mobile_format
 prepend_before_filter :get_geo_location
 before_filter :save_current_controller
 # #before_filter :save_facebook_session
  before_filter :get_username_for_openid
  helper_method :facebook_session
  before_filter :verify_if_facebook, :except => ["facebook_requires_email", "logout", "home_page_map"]
  helper_method :private_mw, :private_mw?
  helper_method :auto_private_mw, :auto_private_mw?

 def try_set_facebook_session
    if(params[:fb_sig_session_key] )
       if(params[:fb_sig])
        set_facebook_session
       end
               return true

    end
    set_facebook_session
    return true
  end
  
  def url_check
    if current_member && private_mw?
      eid = current_member.email.split('@')
      univ = University.find(:first,:conditions => ["url = ?",private_mw]).email_domains.map{|x| x.domain }
      if private_mw? && current_member && params[:action] != "domain_verification"
        acemail = current_member.account_emails.find(:first,:conditions => ["university_name = ?",private_mw])
        if !acemail.nil? &&  acemail.university_name != private_mw && acemail.verified != true
        #~ if !current_member.account_emails.find(:first).nil? && current_member.account_emails.find(:first).university_name != private_mw && current_member.account_emails.find(:first).verified != true
          redirect_to :controller => "invitations",:action => "domain_verification"
        elsif !acemail.nil? &&  acemail.university_name != private_mw && acemail.verified == true #!current_member.account_emails.find(:first).nil? && current_member.account_emails.find(:first).university_name != private_mw && current_member.account_emails.find(:first).verified == true
          redirect_to :controller => "invitations",:action => "domain_verification"
        elsif !acemail.nil? &&  acemail.university_name == private_mw && acemail.verified != true #!current_member.account_emails.find(:first).nil? && current_member.account_emails.find(:first).university_name != private_mw && current_member.account_emails.find(:first).verified == true
          redirect_to :controller => "invitations",:action => "domain_verification"
        elsif acemail.nil?
          redirect_to :controller => "invitations",:action => "domain_verification"
        end
      end
    elsif !current_member && private_mw? and params[:action] != "index" and params[:action] != "do_verify"
      redirect_to "/member"
    end
  end
 
  def private_mw
    val = request.host.split('.')
    if val.length > 1 and val[0] != 'trunk' and val[0] != 'www' and val[0] != 'meetingwave' and !val[0].match('asset')
      university_name ||= val[0]
    elsif val.length > 1 and val[0] != 'trunk' and val[0] == 'www' and val[1] != 'meetingwave' and !val[0].match('asset')
      university_name ||= val[1]
    end  
  end
  
  #~ def private_mw
    #~ val = request.host.split('.')
    #~ if val.length > 1 and val[0] != 'trunk' and val[0] != 'www' and val[0] != 'meetingwave'
      #~ university_name ||= val[0]
    #~ elsif val.length > 1 and val[0] != 'trunk' and val[0] == 'www' and val[1] != 'meetingwave'
      #~ university_name ||= val[1]
    #~ end  
  #~ end
  

  def private_mw?
    private_mw != nil
  end
  
  def auto_private_mw
    if private_mw? && !University.find_by_url(private_mw).alt_paths.nil?
      require 'digest/md5'
      paths = University.find_by_url(private_mw).alt_paths.map{|x| Digest::MD5.hexdigest(x.alumni_url)}
      path = University.find_by_url(private_mw).alt_paths.map{|x| x.alumni_url}
      if !path.blank? && !request.env["HTTP_REFERER"].nil?
        path.each do |match_path|
          if request.env["HTTP_REFERER"].match(match_path)
            @cond = 1
          end
        end
      end
      auto_verify ||= 1 if !request.env["HTTP_REFERER"].nil? && (paths.include?(Digest::MD5.hexdigest(request.env["HTTP_REFERER"])) || @cond == 1)
    end
  end
  

  def auto_private_mw?
    auto_private_mw != nil
  end  
  
  def verify_if_facebook
  
  return true unless(  session[:facebook_session] && !params[:fb_sig] ) # this came from facebook
  
  return true if( current_member && current_member.verified? )
  
  fb_user()

  unless(@fb_user)
    logger.error("Hey what happened here")
    return true 
  end
  
  if( !@fb_user.member.verified? )
   redirect_to( url_for(:controller => "member", :action => "facebook_requires_email") ) and return false 
  end
  return true 
 end
 
 def save_facebook_session
  if(current_member && current_member.social_network_user )
   current_member.social_network_user.set_session(session[:facebook_session])
  end
 end
 
 def self.compute_cache_key(params)
  key_parts = ["action_cache"]   
  params = params.clone
  key_parts << params.delete(:controller)
  key_parts << params.delete(:action)
	    
  params.keys.reject{|p| p.to_s.match(/fb_sig/)}.sort.each_slice(5){ |sub_keys|   
   sub_key = []
   sub_keys.each do |key|
    sub_key << "#{key}_#{params[key]}"
   end  
			
   key_parts << sub_key.join(":")		 
  }   
  return key_parts.collect{|key| key.to_s.gsub("/", ".")}.join("/")
 end

 def compute_cache_key(options = params )
  self.class.compute_cache_key(options)
 end

  protected

  def get_username_for_openid
	  if current_member and current_member.open_id_user? and current_member.user_name.blank?
		  redirect_to username_url
	  else
		  return true
	  end
  end

 class_inheritable_accessor  :current_controller
 def save_current_controller
  ApplicationController.current_controller = self
 end
  
 def validate_recap_with_try_block(*args)
     
  begin
   validate_recap_without_try_block(*args)
  rescue Exception => err
   validate_recap_without_try_block(*args)
  end
 end
  
 alias_method_chain :validate_recap, :try_block
 def admin_required
  if member? and current_member.administrator?
   return true
  else
   redirect_to home_url
   return false
  end
end

 def university_admin_required
  if member? and current_member.university_admin?
   return true
  else
   redirect_to home_url
   return false
  end
 end

 def email_url_params(params)
  return params[:id] if params[:id]
  return (params["#{params[:controller].singularize}_id"] rescue nil)
 end

 def build_query_string(hash)
  # Taken from ActionController::UrlRewriter because I couldn't figure out how
  # to get at the Protected build_query_method.
  elements = []
  query_string = ""

  only_keys ||= hash.keys

  only_keys.each do |key|
   value = hash[key]
   key = CGI.escape key.to_s
   if value.class == Array
    key <<  '[]'
   else
    value = [ value ]
   end
   value.each { |val| elements << "#{key}=#{val}" }
  end

  query_string << ("?" + elements.join("&")) unless elements.empty?
  query_string
 end

 def member2utc(time)
  unless @member.member_profile.nil?
   @member.member_profile.tz.unadjust(time)
  else
   return time
  end
 end

 def utc2member(time)
  unless @member.member_profile.nil?
   @member.member_profile.tz.adjust(time)
  else
   return time
  end
 end
 helper_attr :current_member 

 def current_member
  @current_member ||= (Member.find(session[:member].id) rescue nil   )
 end


 def set_viewer
  member?
  @viewer = Member.find(session[:member].id) rescue nil
 end

 def message_handler(meeting,recipients)
  # This method should probably be moved to the rsvp_controller since it is only
  # used there. confirmations_controller.rb should be removed completely.
  return nil unless params[:message] and @member = current_member
  unless params[:message][:body].blank?
   message = Message.new(params[:message])
   message.meeting = meeting
   message.invitation = meeting.invitation
   message.recipients << recipients
   @member.sent_messages << message
  end
  return message
 end

 # When we set up dev boxes that are not running on localhost, we can add our
 # IPs here to prevent the error notifications from being sent out during
 # development.
 def local_request?
  return false
  ["127.0.0.1"].include?(request.remote_ip)
 end

 def rescue_action_in_public(exception)
  
  begin 
   # Don't send emails for bots...
  if( request.env["HTTP_USER_AGENT"].to_s.match(/bot/i) )   
    redirect_to("/")
    return
  end
  rescue
  end
  
  case exception
  when ActiveRecord::RecordNotFound, ::ActionController::UnknownAction, ::ActionController::RoutingError
   render(:file => "#{RAILS_ROOT}/public/404.html", :status => "404 Not Found")
  else
   render(:file => "#{RAILS_ROOT}/public/500.html", :status => "500 Error")
   SystemNotifier.deliver_exception_notification( self, request, exception)
  end
 end

 def get_geo_location
  if session[:geoip_location].blank? and !request.remote_ip.nil?
   @geoip_location = GeoLocation.new(request.remote_ip)
   @geoip_location.set_default_if_blank
   session[:geoip_location] = @geoip_location
  else
   @geoip_location = session[:geoip_location]
  end

 end



 def set_geo_time_zone
  @geo_location ? @geo_location.time_zone : nil
 end

 def set_profile_time_zone
  if @viewer and @viewer.member_profile
   return @viewer.member_profile.tz || nil
  else
   return nil
  end
 end


 #  include Facebooker::Rails::Controller
 include TTB::FacebookUrlHelper

 def fb_user
  # Grab the facebook user if we have one and store it in the session
  unless( @fb_user  )
   if(sess = session[:facebook_session])  
    user_id =  session[:fb_sig_user] || sess.user.id
    session_key = session[:fb_sig_session_key] || sess.session_key
    expires =     session[:fb_sig_expires] || sess.instance_variable_get("@expires")
    fb_user = SocialNetworkUser.ensure_create_user(user_id, sess.user)   
   else
    user_id =  facebook_params["user"]
    session_key = facebook_params["session_key"]
    expires =     facebook_params["expires"]
    fb_user = SocialNetworkUser.ensure_create_user(user_id, facebook_session.user)
   end
   
   in_profile = params["fb_sig_in_profile_tab"] == "1"
   logger.debug("*****************    Found all we need for FBuser #{user_id} #{session_key} #{expires}")
    
   if( (fb_user.new_record? || fb_user.session_key.nil? || fb_user.session_key != session_key) && !in_profile )
    sess = session[:facebook_session] || facebook_session()      
    fb_user.init_user!( sess )          
   elsif(fb_user.last_access.nil?  || fb_user.last_access < (Time.now - 1.days) || !fb_user.merged_account?)
    fb_user.last_access = Time.now
    fb_user.save!
    end
   @fb_user = fb_user
    
   session[:member] = @fb_user.member
   @fb_user.set_session(session[:facebook_session])
   
  end
  
     return @fb_user

 end
   
 def facebook_user_name
  populate_facebook_user
  facebook_session.user.name
 end
   
 def populate_facebook_user   
  facebook_session.user.populate unless @populate
  @populate = true
 end

 def context?(context)
  if( (params[:context] == "facebook" || params[:context].nil?)  && params[:fb_sig_session_key] )
   params[:context] = :social_network
  end
  return (params[:context].to_s == context.to_s  )
 end

 def check_render_facebook(layout= "noused", action = params[:action]) 
  return false
  layout = layout.call(self) if Proc === layout    
  if(context?(:social_network))
   if( action == :wrapper) 
    action = "/shared/wrapper"
    render :template => "#{action}_fbml", :layout => "#{layout}_fbml"
   else
    render :action => "#{action}_fbml", :layout => "#{layout}_fbml"
   end
   return true
  else
   return false
  end
 end  

 def javascript_redirect_to(url)
  render :text => "<script> window.location = '#{url.gsub("https", "http")}'; </script>", :layout => false
 end
  
 def mobile_request?
  (params[:format] == 'mp')
 end


 def fb_app_name
  ENV["FACEBOOK_APP_NAME"]
 end
  
 # ############ BEBO OVERIDE STUFF
 # 
 # Overide the session create so that we can override the above methods This
 # won't be necessary if we abstract install url api server url , api path rest
 #  def new_facebook_session
 #    if(Facebooker::Session.bebo_request)
 #      Facebooker::BeboSession.create(Facebooker.api_key, Facebooker.secret_key)
 #    else
 #      Facebooker::Session.create(Facebooker.api_key, Facebooker.secret_key)
 #    end
 #  end
  
 # so that admins can score invite from invite show
 def setup_score_inline
  @score_inline = session[:score_inline]
 end  

  
 #  # Setup bebo context.  Itried a prepend before filter here but it didn't work.
 #  def set_facebook_session
 #    set_application_context
 #    super
 #  end
 # 
 #  #  Expose from the class level contenxt whether we are in a bebo request or not.
 # 
 #  def set_application_context
 #     Facebooker::Session.bebo_request =  params[:fb_sig_network] == 'Bebo'
 #  end

 OPEN_WAVE = [/up\.b/i, /up\//i]
 MOBILE_UA_STRINGS = [ /BlackBerry/i, /PalmSource/i, /up\.b/i, /up\//i, /nokia/i ]

 # This method checks for BlackBerry user agents and sets the format parameter
 # accordingly.  'MP' stands for 'Mobile Profile', as in XHTML-MP.
 def set_mobile_format
  logger.debug("user_agent: #{request.env['HTTP_USER_AGENT']}")
  return if session[:user_selected_classic]
  user_agent = request.env['HTTP_USER_AGENT']
  is_openwave = OPEN_WAVE.detect { |regex| user_agent =~ regex }
  is_mobile = (is_openwave or MOBILE_UA_STRINGS.detect { |regex|  user_agent =~ regex })
  if(is_mobile or (params[:force_bb] == 'true') or request.host.starts_with('m.') )
   params[:format]="mp" 
  end
  # There are some special limitations for OpenWave, since it has a very small
  # screen.
  if(is_openwave)
   session[:openwave] = true
  end
 end

 class << self
  # This method allows us to just use one mobile layout, which we call 'mobile'.
  def layout_with_mobile_format_detection(layout_name, conditions = { }, auto = false)
   p = proc{ |controller| (controller.params[:format] == 'mp') ? "mobile" : layout_name }
   layout_without_mobile_format_detection p, conditions, auto
  end
  alias_method_chain :layout, :mobile_format_detection
 end
 
 private
 
  # Hack because I can't figure out what is wrong with this checkbox bug.
  def fix_undisclosed_address_bug 
    if(@invitation.address.airport?)
     key = :undisclosed_address_airport
    else
     key = :undisclosed_address_regular
    end
   params[:invitation][:undisclosed_address] = params[key]
  end
  
  
  
  

end


