require 'ostruct'

require 'facebooker_feed_publisher'
# 
# #Setup your ssh tunnel ssh -R 8888:127.0.0.1:3000 travelerstable_stage
# 
# 
class FacebookController < ApplicationController
 include Facebooker::Rails::Controller
 include TTB::FacebookCanvasHelper

 layout 'facebook'
   
 no_auth_actions = [:get_profile_fbml ,:remove, :setup_session, :default_fbml, :refresh_default_fbml, :dashboard_tab]    
 before_filter :make_sure_not_direct_web, :except => no_auth_actions
 ensure_application_is_installed_by_facebook_user :except => no_auth_actions
# before_filter :ensure_has_offline_access, :except => no_auth_actions
 before_filter :save_off_facebook_info

 before_filter :facebook_params,  :only => [:dashboard_tab]
 before_filter :fb_user , :except => no_auth_actions.concat([:index, :upcoming, :friends_invites, :map, :invite_friends, :feedback])
 #before_filter :ensure_perms
 #before_filter :new_user , :except => no_auth_actions
 #before_filter :grab_flash , :except => no_auth_actions

 def invite_friends
 end

 def index
  #~ home()
 end

 def about
   home()
 end

 def map
  @notice_message = "If you don't find an invite of interest on the map, try <a href='#{browse_url(:canvas => false)}'>Search Meetings </a>"
  render :text => %Q{<fb:iframe src="http://#{request.host_with_port}/map/embeded/iframe" height="600" width="100%" scrolling="no" style="margin:auto;" name="ttb_frame" id="ttb_frame"></fb:iframe>} , :layout => true
 end

 def feedback
 end
 
 def require_perms
 end

 # Callback URL when a user removes the app.  I am a little confused by why the
 # Facerbooker auth stuff doesn't work here. Hopefull the call to
 # new_facebook_session is good enough.
 def remove
  begin
   SocialNetworkUser.removed_application(params[:fb_sig_user]) 
  rescue 
   logger.error("FB:: ERROR:: 'remove'  #{$!.message}")
  end
  render :text => "Done"
 end

 # Currently this goes to me we need an email alias.
 def send_feedback
  @facebook_user = facebook_session.user
  FacebookFeedback.deliver_feedback(@facebook_user,params[:subject],  params[:feedback])
  @fb_user.flash_message = "Thanks, #{@facebook_user.first_name}.  Your feedback has been recieved. "
  @fb_user.save!
  render :text => "<fb:redirect url='#{canvas_url("upcoming")}'/> " , :layout => false
 end

 # Hook up accounts and or create and accounton TTB.
 def link
  begin
   if(@member = Member.authenticate(params['member']['email'], params['member']['password']))
    fb_user.member =  @member
    fb_user.save!
    @message = "You have now  linked your Facebook and MeetingWave accounts."
   elsif (Member.find_non_verified(params['member']['email']))
    @error_message = "This account has not been verified. Please check your email and click the verification link."
   else
    @login = params['member']['email']
    @error_message =  'The credentials you entered were not recognized.  Please try again. '
   end
  rescue
   logger.error("FB join error #{$!.message} ")
   @error_message = " Errors creating account. Did you fill everything out correctly?"
  end
  @member ||= Member.new

  render :action => "settings"
 end

 def home
  @invites = LookUp.invites_for_upcoming_on_home[0..5]
  render :action => "home"
 end

 # Meetings near you.
 def upcoming 
  fb_user()
  if(@fb_user && ( @fb_user.has_location? || ( @fb_user.member && @fb_user.member.has_location? ) ) )
   @invites, @geoip_loc = @fb_user.upcoming_invitations(:limit => 12)
  else
   @error_message = "We don't have enough information to find meetings near you. Make sure you set your location details under profile settings above."
   @invites = []
  end
 end
  
 def dashboard_tab
  @no_session_passing = true
  @fb_user = FacebookUser.find_by_uid(params[:fb_sig_profile_user])
  render :layout => "facebook_tab", :action => 'dashboard_tab'
 end

 # Saving setttings.
 def settings
  if(params[:save_location])
   if(!@fb_user.valid? || !@fb_user.update_attributes(params[:user]    ))
        logger.debug(" errror saveing fb user" + @fb_user.errors.full_messages.join("\n")) 
   end
   
      
   if( member_profile = @fb_user.member.member_profile rescue nil )   
    member_profile.current_city = @fb_user.city if(@fb_user.city)
    member_profile.current_state = @fb_user.state if(@fb_user.state)
    member_profile.current_country = @fb_user.country if(@fb_user.country)
    member_profile.save
   end
   
   render :text => "<fb:redirect url='#{canvas_url('settings')}'/> ", :layout => false
   update_profile(@fb_user)
  end
 end        

 def edit_page
  @page_id = params[:fb_page_id]

  if  params[:save_location]
   @page = OpenStruct.new(params[:page])
   logger.debug("Saving settings for #{@page.to_yaml}")

   fb_user.set_page_settings(@page_id, params[:page])
   fb_user.save!
   update_profile(fb_user, @page_id)
  else
   @page = OpenStruct.new(fb_user.pages[@page_id] )
   @page.number_on_profile ||= 5
  end
  render :layout => false
 end

 # Search page.
# def browse
#  render_iframe(ssearch_url( :only_path => false, :canvas => false, :context =>  "social_network"))
# end

 def invite_friends_to_invite
  @invitation = Invitation.find(params[:id])
  @inviter_name = fb_user.name
 end

 # Profile box
 def get_profile_fbml
  @fb_user ||= SocialNetworkUser.find(params[:id])
  setup_profile_for_user(@fb_user,params[:facebook_page_id])
  render :partial => 'get_profile_fbml', :layout => false
 end
 
# def faq
#    url = facebook_faq_url( :only_path => false, :canvas => false, :context =>  "social_network")
#          
#    style = "width:636px;height:500px;margin:auto;"
#                   
#    render :text => %Q{<fb:iframe src="#{url}" scrolling="auto" style=#{style} name="ttb_frame" id="ttb_frame"></fb:iframe>} , :layout => true
#
# end

 def setup_profile_for_user(fb_user, page_id = nil)
  if( page_id)
   page =  OpenStruct.new(fb_user.pages[page_id])
   logger.debug(" Getting profile FBML for page. #{page_id} #{page.to_yaml} ")

   fb_user.include_upcoming_invitations = "true"
   fb_user.city = page.city
   fb_user.state = page.state
   fb_user.country = page.country
   fb_user.zip = page.zip
   fb_user.number_on_profile = page.number_on_profile
   fb_user.include_my_invitations = false
  end
  
  if( fb_user && fb_user.include_upcoming_invitations == "true")
   if( ( fb_user.has_location? || ( fb_user.member && fb_user.member.has_location? ) ) )
    @upcoming_invites, @geoip_loc = fb_user.upcoming_invitations()
   end

   unless(@upcoming_invites && @upcoming_invites.length > 0)
    @upcoming_invites = LookUp.invites_for_upcoming_on_fbprofile(:limit => fb_user.number_on_profile.to_i)
    @upcoming_invites = @upcoming_invites.sort_by { |inv| inv.upcoming_meeting.start_time_local rescue 0 }
    @geoip_loc = nil
   end
  end

  if(fb_user && fb_user.merged_account? && fb_user.include_my_invitations == "true")
   @my_invitations = (fb_user.member.posted_invites ).reject(&:closed?)[0...fb_user.number_on_profile.to_i]
  end
      
  if(@upcoming_invites)
   @upcoming_invites = @upcoming_invites[0...fb_user.number_on_profile.to_i] 
  end           
 end

 def push_new_profile
  update_profile(fb_user)
  @message = " Your profile has been updated. "
  render :action => "settings"
 end  
# def my_profile
#
#  render_iframe(my_profile_url( :only_path => false, :canvas => false, :context =>  "social_network"))
# end
#
# def post_invite
#  render_iframe(postinvite_url( :only_path => false, :canvas => false))
# end
#
# def dashboard
#  render_iframe(my_invites_url(:only_path => false, :canvas => false)  )
# end
# This needs to be a redirect now.
 def invite_show
  render_iframe(show_invite_url(:only_path => false, :canvas => false,  :id => params[:id], :meeting_id => params[:meeting_id])  )
 end 
 def member_profile_show
  render_iframe(member_profile_url(:only_path => false, :canvas => false,  :id => params[:id])  )
 end    
  
 def new_user 
  render_iframe(url_for(:controller => "get_started", :action => "step1", :only_path => false, :canvas => false, :context => "social_network"), "width:646px;height:1000px;border:0px;", 'fb_flow')
 end

 def friends_invites
  @friends =  facebook_session.user.friends
  @fb_users = SocialNetworkUser.find_all_by_uid( @friends.map(&:id), :conditions => [" meetings.start_time >= ?", Time.now.utc ],:include => {:member => {:invitations => :meetings}})  
  @invites = @fb_users.map(&:member).compact.map(&:invitations).flatten.compact.select(&:open?).map{|invite| 
   invite.meetings.detect{|meeting| 
    meeting.start_time > Time.now.utc
   }
  }.compact.sort_by(&:start_time)  
	     
  found_friends = @fb_users.map(&:uid)
  @friends = @friends.select{|friend| found_friends.include?(friend.id)}
 end
 # Override this so that we get redirected to the right place.
 def application_is_not_installed_by_facebook_user
  redirect_to new_facebook_session.install_url(:next => next_path() )
 end
 
  def ensure_has_offline_access
        has_extended_permission?("offline_access") || application_needs_permission("offline_access")
      end
      
      def application_needs_permission(perm)
        redirect_to(facebook_session.permission_url(perm, :next => "#{url_for(:action => :index, :canvas => true, :only_path => false)}#{next_path()}"))
      end 
 
# def update_empty
#  render :inline => "HEY THERE. #{Time.now.to_s}"
# end
# 
# def update_empty_rjs
#  render :inline =>  "document.getElementById('rjs_updater').setStyle({display: \'block\'}) "   
# end
  
 def look_at_facebook_fbml
  render :inline => CGI.unescapeHTML(SocialNetworkUser.find(params[:id] || @fb_user.id).create_session.user.profile_fbml)
 end
  
 def default_fbml
  @upcoming_invites = LookUp.invites_for_upcoming_on_fbprofile(:limit => 5) 
  @upcoming_invites = @upcoming_invites.sort_by { |inv| inv.upcoming_meeting.start_time_local rescue 0 }
  @geoip_loc = nil
  render :partial => 'get_profile_fbml', :layout => false 
 end
  
 def refresh_default_fbml
  url = url_for(:action => "default_fbml", :canvas => false, :only_path => false)
  # #facebook_session.user.profile_fbml = "<fb:ref url='#{url}'/>"
  begin
   Facebooker::Session.runner_mode = true
   FacebookUser.find_by_name("David Clements").create_session.server_cache.refresh_ref_url(url)
  ensure
   Facebooker::Session.runner_mode = false
  end
  render :inline => "<fb:ref url='#{url}' />"
 end
  

 private
 
  def after_facebook_login_url
        next_path
  end
   
 def next_path
  path = "#{params[:controller]}/#{params[:action]}?"
  path = "/#{path}" unless Facebooker::FacebookAdapter.new_api? || Facebooker.is_for?(:bebo)
  if(params[:controller] == 'facebook' && params[:action] == 'index')
   return path # No longer give them the flow 
  end
  non_keys = ["controller", "method", "action","format", "_method", "auth_token"]
  parts = []
  params.each do |k,v|
   next if non_keys.include?(k.to_s) || k.to_s.starts_with("fb")      
   parts << "#{k}=#{v}"
  end
  path + parts.join("&")     
 end

 def render_iframe(url, style = "width:646px;height:2000px;margin:auto;", layout = true)
  render :text => %Q{<fb:iframe src="#{url}" scrolling="no" style=#{style} name="ttb_frame" id="ttb_frame"></fb:iframe>} , :layout => layout
 end

 #  def new_user
 # ##    if(fb_user.new_user? ) ##      update_profile(fb_user) ##    end
 #  end


 # Fork a proc and update the fbml
 def update_profile(fb_user, page_id = nil)
  page_id = nil if page_id.blank?
  logger.debug("FB: Updating fbml for #{fb_user.uid} #{page_id}")

  setup_profile_for_user(fb_user, page_id)

  action_view = ActionView::Base.new( Rails::Configuration.new.view_path, {},  self)
  action_view.extend(Facebooker::Rails::Helpers)
  fbml =  	action_view.render(:partial => 'get_profile_fbml',
   :locals => {:fb_user => @fb_user, :geoip_loc => @geoip_loc,
    :upcoming_invites => @upcoming_invites, :my_invitations => @my_invitations})
  user_id = page_id.blank? ? fb_user.uid : page_id
  user = Facebooker::User.new(user_id) 

  user.profile_fbml = fbml 

  logger.debug("Finished updating fbml for User: #{fb_user.uid} Page:  #{page_id} ")
 end

 def grab_flash
  @message ||= flash[:info]
  @notice_message  ||= flash[:notice]
  @error_message ||= flash[:error]
 end
  
 def make_sure_not_direct_web
  begin
   redirect_to(url_for(params.merge(:canvas => true))) unless params[:fb_sig]
  end
 end
 
 def ensure_perms
  if(@fb_user.offline_access?)
   return true
  else
   render :action => "require_perms" and return false
  end
 end
 
  def save_off_facebook_info
   session[:fb_sig_user] = params[:fb_sig_user]
   session[:fb_sig_session_key] = params[:fb_sig_session_key]
   session[:fb_sig_expires] = params[:fb_sig_expires]
 end

end

 




#    def test_ajax
# 
#  end
# 
#  def update_empty
# 	   render :inline => "HEY THERE."
# 	end
# 
# def auto_complete_for_member_name
#   members = Member.find(:all,
#     :conditions => [ 'LOWER(user_name) LIKE ?', params[:suggest_typed].downcase + '%'],
#     :order => 'user_name ASC',
#     :limit => 10).map(&:user_name)
#   render :text => "{fortext:#{params[:suggest_typed].to_json},results:#{members.to_json}}"
# end


# def test
#     fb_user
#     render :text => ( session[:fb_user].inspect || [:empty] ), :layout => false
#  end
# 


# 
# def profile
#    @user = facebook_session.user
# 
#    @user.profile_fbml= Time.now.to_s +  " updated the profile box"
#    @user.friends_with_this_app.each{|friend| friend.profile_fbml = Time.now.to_s + " #{@user.first_name} updated the profile box."}
# end
# 
# def story
#    @user = facebook_session.user
#    story = Facebooker::Feed::Story.new()
#    story.title = "#{@user.first_name} just publish a story using facebooker api. at #{Time.now}"
#    story.body = "Wondering what happens here. when I add it to friend as well."
#    @user.publish_story(story)
# 
# end
# 
# def action
#    @user = facebook_session.user
# 
#    action = Facebooker::Feed::TemplatizedAction.new
#    action.actor_id = @user.id
#    action.title_template = "{actor} did somethign during templatized action. We should see it elsewhere."
#    @user.publish_templatized_action(action)
# end
# 
# def now
#    render :inline => Time.now.to_s
# end
