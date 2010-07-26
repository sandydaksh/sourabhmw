require 'email.rb'
require 'email_admin_actions'
require 'facebook_admin_actions'
class Admin::BackdoorController < ApplicationController   
  include TTB::EmailAdminActions
    include TTB::FacebookAdminActions

  layout 'admin'
  before_filter :admin_required, :except => "backdoor_stats"

  tiny_mce_options = {:theme => 'advanced',
      :browsers => %w{msie gecko},
       :convert_urls => false,

      :theme_advanced_toolbar_location => "top",
      :theme_advanced_toolbar_align => "left",
      :theme_advanced_resizing => true,
      :theme_advanced_resize_horizontal => false,
      :paste_auto_cleanup_on_paste => true,
      :theme_advanced_buttons1 => %w{ link unlink formatselect },
      :theme_advanced_buttons2 => [],
      :theme_advanced_buttons3 => [],
      :relative_urls => false,
      :plugins => %w{contextmenu paste}}
  uses_tiny_mce(:options => tiny_mce_options , :only => [:facebook_notifier])
 
  tiny_mce_options =   tiny_mce_options.merge(:theme_advanced_buttons1 => %w{link unlink formatselect bold code})
  uses_tiny_mce(:options => tiny_mce_options , :only => [ :facebook_emailer])
  def email
    @members = Member.find(:all, :conditions => [ 'verified = 0'])
  end
  
   def manually_verify_user
    id = params[:member_id]
    key = params[:key]
    if id and key
      member = Member.authenticate_by_token(id, key)
      flash[:notice] = "#{member.email} has been manually verified."
    end
    
    redirect_to :action => "email"

  end

  def index
    @invitation_count = Invitation.count
    @invitation_accepted_count = Confirmation.count(:all, :conditions => [ "status_id = ? ", Status['accepted'].id])
    @invitation_declined_count = Confirmation.count(:all, :conditions => [ "status_id = ? ", Status['declined'].id])
    @user_count = Member.count
    @user_verified_count = Member.count(:all, :conditions => [ " verified = 1 "])
    @user_unverified_count = Member.count(:all, :conditions => [ " verified = 0 "])
    @user_deleted_count = DeletedAccount.count
  end

  def unverified
    @unverified_users = Member.find(:all, :conditions => [ "verified = 0 AND created_at > '2007-05-30 12:00:00'"], :order => "created_at DESC")
    return
  end

  def resend_confirm
    unless request.post?
      redirect_to :action => 'unverified'
      return
    end
    @members = Member.find(params[:selected_members])
  end

def resend
    unless request.post?
      redirect_to :action => 'unverified'
      return
    end

    @members = Member.find(params[:selected_members])

    @members.each do | m |
      key = m.generate_security_token
      url = "http://www.meetingwave.com/member/welcome/#{m.id}/#{key}"
      level = m.university_name if m.university_name != 'public'
      MemberNotify.deliver_signup(m, '',level, url)
    end

  end

  def facebook_notifier
    @users_options = [:all,:just_us]
  end  

  def facebook_emailer
    @users_options = [:all,:just_us, :just_me]
  end   

  def send_facebook_emails
    #Facebooker::Session.runner_mode = true
    begin
      @html = params[:html_version]
      @text = params[:text_version]
      @subject = params[:subject]
       only_us = !( params[:users] == "all" )

      if( @html.blank? && @text.blank? || @subject.blank?)
        @errors = ""
        @errors += " You must either put in html or text for the email."  if ( @html.blank? && @text.blank? )
        @errors += " You must have a subject. " if @subject.blank?
      else
        @html = nil if @html.blank?
        @text = nil if @text.blank?
        SocialNetworkUser.push_emails(@subject, @text, @html, only_us)
      end
    
    ensure
     # Facebooker::Session.runner_mode = false
    end
   
  end    

    
  def send_facebook_notifications
    #Facebooker::Session.runner_mode = true
    @errors = ""
    begin
       @notification = params[:notification] 

       only_us = !( params[:users] == "all" )

      if( @notification.blank? )
        @errors += " You must something in there." 
      else
       
        SocialNetworkUser.push_notification( only_us, @notification)
      end
    
    ensure
     # Facebooker::Session.runner_mode = false
    end
  end

  def email_subscribers
    @subscribers = Member.find(:all, :conditions => ['receives_news_updates = 1 and email IS NOT NULL and email != "" ' ])
    @non_subscribers = Member.find(:all, :conditions => ['receives_news_updates != 1'])
  end

  def backdoor_stats
    time_conditions = ["created_at > ? and created_at < ?", 1.hour.ago.gmtime, Time.now.gmtime]
    results = {}
    [:confirmation, :member, :invitation, :message].each do |table|
      results[table] = table.to_s.camelize.constantize.find(:all, :select => "id", :conditions => time_conditions).length
    end
    results = results.collect{|table, count|  "#{table.to_s.pluralize}:#{count} "}.join("<br>")
    render :text => <<-EOL
     #{results}
EOL
  end

  private

  def disable_in_production
    if((RAILS_ENV == 'production') and (Socket::gethostname == '108252-www1.travelerstable.com'))
      redirect_to home_url
      return false
    else
      return true
    end
  end
  
   private
  before_filter :save_asset_host
 after_filter :return_asset_host
 def save_asset_host
    @asset_host = ActionController::Base.asset_host
    
  ActionController::Base.asset_host = request.host_with_port
 end
 
 def return_asset_host
  ActionController::Base.asset_host = @asset_host
 end

end
