
class MemberController < ApplicationController
 unless(RAILS_ENV == 'development')
  #  include SslRequirement
  #    ssl_required :all
 end
 before_filter :private_global
 layout 'account'
 helper :invitations
    
 before_filter :force_login, :only => [:welcome]
 before_filter :login_required, :except => [:index, :login, :signup, 
  :forgot_password, :generate_blank, 
  :pre_verified_signup, :verification_needed, 
  :signup_successful, :must_verify_first]
 skip_before_filter :verify_if_facebook
 def login
  if !auto_private_mw.nil? || (!params[:sessval].nil? && params[:sessval] != "")
    session[:alumni_url] = "1"
  else
    session[:alumni_url] = nil
  end   
   
  if request.get?
   @member = Member.new
   render :layout => 'signup' unless mobile_request? 
   return 
 end
 
  @member = Member.new(params['member'])
  session[:member] = Member.authenticate(params['member']['email'], params['member']['password'])
  
  if session[:member]
    if private_mw?   ## Block to enter when alumni do signup with his/her university id.
      if session[:alumni_url] == "1"
        @account = AccountEmail.new()
        @account.member_id = session[:member].id
        @account.verification_code = AccountEmail.random_string(10)
        @account.university_name = private_mw
        @account.verified = 1
        @account.email = session[:member].email
        @account.save
        session[:alumni_url] = nil
      end
    end
    
   if params[:remember] == "1"
    session[:member].remember_me
    cookies[:auth_token] = { :value => session[:member].remember_token , :expires => session[:member].remember_token_expires_at }  
   end          
      
   cookies[:ttb_user_name] = session[:member].fullname
   #redirect_back_or_default :controller => 'invitations', :action => 'myinvitations' ======== "we changed"
   
    if !session[:meeting_id].nil? && !session[:meeting_id].blank?
       event_name = Invitation.find(:first,:conditions =>["id = ?",session[:meeting_id]]) if session[:meeting_id]
       if !event_name.nil? && event_name.inviter.id != current_member.id
         meet = event_name.upcoming_meeting if event_name
         
         
         @meeting   = Meeting.find(meet.id)
         @invitation = @meeting.invitation
        
        invitee = current_member
        @meeting =  Meeting.find(meet.id)
        # Get the confirmation for this meeting and user.  Hopefully, we either build a new one or we 
        # find one with a satus of 'Saved'--that is, one where the user has not already accepted.
        @confirmation = @meeting.confirmations.find_by_member_id(invitee.id) 
        if @confirmation.nil?
          @confirmation = @meeting.confirmations.build(:status_id => Status[:accepted].id, :member_id => invitee.id, :invitation_id => @meeting.invitation_id)
        end
            
        @confirmation.status = Status[:accepted] 
        @invitation.confirmations << @confirmation
        invitee.confirmations << @confirmation
        if @confirmation.save!
          url_invite = show_invite_url(:id => @invitation.id, 
                                       :meeting_id => (@meeting.id rescue nil),
                                       :member_id => @invitation.inviter.id, 
                                       :key => @invitation.inviter.generate_security_token) 
          message = message_handler(@meeting,[@invitation.inviter])
        end
      end
    end
    session[:meeting_id] = nil
    email_checking
   return
  elsif (Member.find_non_verified(params['member']['email']))
   redirect_to :action => 'must_verify_first'
   return
  else
   @login = params['member']['email']
   flash[:loginerror] = 'The credentials you entered were not recognized.  Please try again. '
  end
  if params[:sessval].nil? or params[:sessval] == ""
    javascript_redirect_to(url_for(:action => "signup")) unless mobile_request?
  else
    javascript_redirect_to(url_for(:action => "signup",:sessval => params[:sessval])) unless mobile_request?  
  end
 end

  def email_checking
    if private_mw?
      eid = current_member.email.split('@')
      univ = University.find(:first,:conditions => ["url = ?",@univ_account]).email_domains.map{|x| x.domain }
      puts univ.inspect
      if univ.include?(eid[1])
        redirect_to :controller => 'invitations', :action => 'myinvitations'
      else
        acemail = current_member.account_emails.find(:first,:conditions => ["university_name = ?",@univ_account])
        if !acemail.nil? &&  acemail.university_name == @univ_account && acemail.verified == true
          redirect_to :controller => 'invitations', :action => 'myinvitations'
        else
          redirect_to :controller => 'invitations', :action => 'domain_verification'
        end
      end
    else
        redirect_to :controller => 'invitations', :action => 'myinvitations'      
    end
  end
 
 def facebook_requires_email
  render :layout => 'signup'
 end
 
 def set_email_for_facebook
  @member = current_member
  if ( params['member']['email'].blank? )
     flash[:error] = "You must enter a valid email address"
     
     redirect_to :action => "facebook_requires_email" and return
  end
  
  
  if(  Member.find_by_email(params['member']['email']) )
   
   if( params['member']['password'] )
   begin
    #~ if !private_mw?
      #~ @member = Member.authenticate_public(params['member']['email'], params['member']['password'],@univ_account)
    #~ else
      #~ @member = Member.authenticate_private(params['member']['email'], params['member']['password'],@univ_account)
    #~ end
    @member = Member.authenticate(params['member']['email'], params['member']['password'])
    if(@member)
     fb_user.member =  @member
     fb_user.save!
     session[:member] = @member
     redirect_to("/")
     return
     
    elsif (Member.find_non_verified(params['member']['email']))
     flash.now[:error] = "This account has not been verified. Please check your email and click the verification link."
    else
     @login = params['member']['email']
     flash.now[:error] =  'The credentials you entered were not recognized.  Please try again. '
    end
   rescue
    logger.error("FB join error #{$!.message} ")
    flash.now[:error] = " Errors creating account. Did you fill everything out correctly?"
   end
  else
      flash.now[:error] =  "You already have an account on MeetingWave.  "
  end
      flash.now[:notice] = "Enter your Email Address and Password to link your Facebook and MeetingWave accounts"
      render :action => "facebook_user_has_account" , :layout => 'signup'

  else
   @member.email = params['member']['email']
   key = @member.generate_security_token
   
   MemberNotify.deliver_signup_f(@member, params['member']['password'], welcome_url(:member_id => @member.id, :key => key))
   flash[:notice] = l(:member_signup_succeeded)
   logger.error(" REDIRECTING TO : #{url_for(:action => 'signup_successful', :email => @member.email)}")
   redirect_to( url_for(:action => 'signup_successful', :email => @member.email )) # This is so that protocol switches.  
  end
  
 end

 def signup
    if !auto_private_mw.nil? || (!params[:sessval].nil? && params[:sessval] != "")
      session[:alumni_url] = "1"
    else
      session[:alumni_url] = nil
    end   
    
  if request.get?
    @member = Member.new(params[:member])
    render :layout => 'signup' unless mobile_request?
    return 
  end
  params['member'].delete('form')
  @member = Member.new(params['member'])
  @member.new_password = true

  if(mobile_request?)
   saved = @member.save
  else
   # The old way... @member.save_with_captcha The new way...
   if ( dont_have_super_secret_password? and !validate_recap(params, @member.errors) )
    @captcha_error = true
    @member.valid? # trigger validation
    @member.errors.add(:captcha, "Captcha words incorrect.")
    saved = false
   else
    saved = @member.save
   end
  end
  ## Updating user_id field when a private mw user do signup.
  #Alumini.connection.execute("update aluminis set user_id = #{@member.id} where id = #{session[:alumini_id]}") if (saved) && !session[:alumini_id].nil?

  if (saved)
    if private_mw?   ## Block to enter when alumni do signup with his/her university id.
      if session[:alumni_url] == "1"
        @account = AccountEmail.new()
        @account.member_id = @member.id
        @account.verification_code = AccountEmail.random_string(10)
        @account.university_name = private_mw
        @account.verified = 1
        @account.email = @member.email
        @account.save
        session[:alumni_url] = nil
      else
        eid = @member.email.split('@')
        univ = University.find(:first,:conditions => ["url = ?",private_mw]).email_domains.map{|x| x.domain }
        if univ.include?(eid[1])
          @account = AccountEmail.new()
          @account.member_id = @member.id
          @account.verification_code = AccountEmail.random_string(10)
          @account.university_name = private_mw
          @account.verified = 1
          @account.email = @member.email
          @account.save
        end
      end
    end
    
   key = @member.generate_security_token
   event_name = Invitation.find(:first,:conditions =>["id = ?",session[:meeting_id]]) if session[:meeting_id]
   @meeting = event_name.upcoming_meeting if event_name
   #~ if session[:alumini_id].nil?
   if private_mw?
     type=private_mw 
   else
     type=nil   
   end    
   
   MemberNotify.deliver_signupwithmeeting(@member, params['member']['password'],event_name.name, welcome_url(:member_id => @member.id, :key => key,:eventid => event_name.name,:meeting_id => @meeting.id)) if event_name
   MemberNotify.deliver_signup(@member, params['member']['password'],type, welcome_url(:member_id => @member.id, :key => key)) if !event_name
   #~ else ## When a private mw user do signup.
     #~ MemberNotify.deliver_signupwithmeeting(@member, params['member']['password'],event_name.name, welcome_url(:member_id => @member.id, :key => key,:eventid => event_name.name,:meeting_id => @meeting.id)) if event_name
     #~ MemberNotify.deliver_signup(@member, params['member']['password'], welcome_url(:member_id => @member.id, :key => key)) if !event_name
   #~ end
   session[:meeting_id] = nil
   #~ MemberNotify.deliver_signup(@member, params['member']['password'], welcome_url(:member_id => @member.id, :key => key))
   flash.now[:notice1] = l(:member_signup_succeeded)
   logger.error(" REDIRECTING TO : #{url_for(:action => 'signup_successful', :email => @member.email)}")
   redirect_to( url_for(:action => 'signup_successful', :email => @member.email , :uname => @member.user_name)) # This is so that protocol switches.
   return
   
  else
         flash[:rendered_errors] =  TTB::MasterHelper.new(self, :member => @member).error_messages_for('member', 
                        :attributes_order => [:first_name, :last_name, :email, 
                                              :user_name, :password, :terms_of_service, :captcha], 
                          :header => 'Please correct the following errors before we create your account:')
  end
  if params[:sessval].nil? or params[:sessval] == ""
    javascript_redirect_to(url_for(:action => "signup", 'member[email]' => @member.email, 'member[user_name]' => @member.user_name, 'member[terms_of_service]' => @member.terms_of_service)) unless mobile_request?
  else 
    javascript_redirect_to(url_for(:action => "signup", 'member[email]' => @member.email, 'member[user_name]' => @member.user_name, 'member[terms_of_service]' => @member.terms_of_service,:sessval => params[:sessval])) unless mobile_request?
  end
 end
    
 def signup_successful
  @member = Member.new(:email => params[:email])
  render :layout => 'signup' unless mobile_request?
 end
  
 def must_verify_first
  render :layout => 'signup' unless mobile_request?
 end
  
 def pre_verified_signup
  @non_member = NonMember.find_by_security_token(params[:security_token])
  @invite_response = params[:response]
  @invite_id = params[:id]
  if params[:member].nil?
   @member = Member.new(:email => @non_member.email, :verified => true)
   return 
  else
   @member = Member.new(params[:member])
   @member.new_password = true

   if !validate_recap(params, @member.errors) 
    @captcha_error = true
    @member.valid? # trigger validation
    @member.errors.add(:captcha, "Captcha words incorrect.")
   else
    if @member.save
     if @member.email != @non_member.email
      key = @member.generate_security_token
      @member.verified = false
      @member.save
      url = welcome_with_response_url(:member_id => @member.id, :key => key, :id => @invite_id, :response => @invite_response, :non_member_key => @non_member.security_token)
      MemberNotify.deliver_signup(@member, params['member']['password'], url)
      redirect_to :action => 'verification_needed', :email => @member.email, :invite_response => @invite_response      
     else
      @member.verified = true
      @member.save
      session[:member] = @member
      cookies[:ttb_user_name] = session[:member].fullname
			
      # ## Check for nonmember records to convert to confirmations
      convert_non_member_approvals(@non_member)
      redirect_to pre_verified_response_url(:id => @invite_id, :response => @invite_response)    
     end
    end
   end
  end    
 end
  
 def verification_needed
  @email = params[:email]
  @invite_response = params[:invite_response]
 end
  
 def logout
  session[:university] = nil
  session[:member].forget_me unless session[:member].nil?
  cookies.delete :auth_token   
  cookies.delete :ttb_user_name 
  session[:facebook_session] = nil
  session[:member] = nil    
  clear_fb_cookies!
  redirect_to url_for(:controller => "invitations", :action => "index")
 end

 def change_password
  if private_mw?
    eid = current_member.email.split('@')
    univ = University.find(:first,:conditions => ["url = ?",@univ_account]).email_domains.map{|x| x.domain }
    if univ.include?(eid[1])
      @pi_vate = "1"
    else
      acemail = current_member.account_emails.find(:first,:conditions => ["university_name = ?",@univ_account])
      if !acemail.nil? &&  acemail.university_name == @univ_account && acemail.verified == true
        @pi_vate = "1"
      else
        @pi_vate = "2"
      end
    end
  end
  
  return if generate_filled_in
  params['member'].delete('form')
  
  begin
   @member.change_password(params['member']['password'], params['member']['password_confirmation'])
   if @member.save
    url = url_for(:action => 'login')
    MemberNotify.deliver_change_password(@member, params['member']['password'], url)
    flash[:notice] = "Your password has been successfully updated.  A notification email has been sent to #{@member.email}."
    @member.password_confirmation = nil
    
    if private_mw?
      eid = @member.email.split('@')
      univ = University.find(:first,:conditions => ["url = ?",@univ_account]).email_domains.map{|x| x.domain }
      if univ.include?(eid[1])
        redirect_to :controller => 'invitations', :action => 'myinvitations'
      else
        acemail = current_member.account_emails.find(:first,:conditions => ["university_name = ?",@univ_account])
        if !acemail.nil? &&  acemail.university_name == @univ_account && acemail.verified == true
          redirect_to my_account_url
        else
          redirect_to :controller => 'invitations', :action => 'domain_verification'
        end
      end
    else
        redirect_to my_account_url
    end
    
   end
  rescue
   flash.now[:notice] = l(:member_change_password_email_error)
  end
 end
  
 def forgot_password
  if !auto_private_mw.nil? || (!params[:sessval].nil? && params[:sessval] != "")
    session[:alumni_url] = "1"
  else
    session[:alumni_url] = nil
  end   
   
  # Always redirect if logged in
  if member?
   flash[:notice] = l(:member_forgot_password_logged_in)
   redirect_to :action => 'change_password'
   return
  end

  # Render on :get and render
  return if generate_blank

  # Handle the :post
  #~ @member = Member.find(:first,:conditions => ["email = ? and university_name = ?",params['member']['email'],@univ_account]) || Member.new(params['member'])
  @member = Member.find(:first,:conditions => ["email = ?",params['member']['email']]) || Member.new(params['member'])
  unless @member.valid?
   @header = 'There was a problem with your input.'
   unless @member.errors.on(:email)
    @member.errors.add(:email, " address: #{params['member']['email']} wasn't found in our records.")
   end
  else
   begin
    if private_mw?   ## Block to enter when alumni do signup with his/her university id.
      if session[:alumni_url] == "1"
        @account = AccountEmail.new()
        @account.member_id = @member.id
        @account.verification_code = AccountEmail.random_string(10)
        @account.university_name = private_mw
        @account.verified = 1
        @account.email = @member.email
        @account.save
      end
    end
    auth = build_query_string( :member_id => @member.id, :key => @member.generate_security_token )
    url = url_for(:action => 'change_password') + auth
    MemberNotify.deliver_forgot_password(@member, url)
    flash[:notice1] = "We've sent an email to #{@member.email}  with instructions on resetting your password."
    unless member?
    if session[:alumni_url] == "1"
      redirect_to :action => "signup",:sessval => session[:alumni_url]
    else
      redirect_to signup_url
    end
    session[:alumni_url] = nil
     return
    end
    redirect_back_or_default :action => 'welcome'
   rescue
    flash.now[:notice] = l(:member_forgotten_password_email_error, "#{params['member']['email']}")
   end
  end
 end

 EDITABLE_FIELDS = ['first_name', 'last_name', 'user_name', 'email', 'terms_of_service', 'default_reminder_advance', 
  'receives_news_updates', 'cell_phone_number', 'cell_phone_prefix', 'receives_sms_reminders', 'receives_sms_invites']

 def edit
  @member = current_member

  if request.get?
   render :layout => 'account'
   return
  end

  if params['member'] and params['member']['form']
   form = params['member'].delete('form')
   case form
   when "edit"
    pass = params['member']['password']
    pass_conf = params['member']['password_confirmation']
    member_params = params['member'].delete_if { |k,v| (not EDITABLE_FIELDS.include?(k)) }
    logger.error("MEMBER_PARAMS: #{member_params.inspect}")
    @member.change_password(pass, pass_conf) unless pass.blank?
    if @member.update_attributes(member_params) and @member.save
     session[:member] = @member
     cookies[:ttb_user_name] = @member.fullname
     flash[:notice] = "Your account has been updated."  
    
    else
     if(context?(:social_network))
      flash[:error] = "Couldn't update your user account. #{@member.errors.full_messages.join("\n")}"
     else
      flash[:rendered_errors] =  TTB::MasterHelper.new(self, :member => @member).error_messages_for(:member, :header => 'We were unable to update your account.  Please correct the following errors:')
     end
      
    end   
    if context?(:social_network)
     redirect_to( canvas_url("settings")   ) 
     return
    end
   when "change_password"
    change_password
   else
    raise "unknown edit action"
   end
  end
    
  javascript_redirect_to my_account_url
 end
  
 def confirm_delete
  render :layout => "account"
 end
  
 def delete
  @member = session[:member]
  begin
   destroy(@member)
   session[:member] = nil
   redirect_to ''
  rescue => e
   logger.error("Error while deleting: #{$!}, #{e.backtrace.join("\n")}")
   flash.now[:notice] = l(:member_delete_email_error, "#{@member['email']}")
   redirect_to home_url
  end
 end

 def restore_deleted
  @member = session[:member]
  @member.deleted = 0
  if not @member.save
   flash.now['notice'] = l(:member_restore_deleted_error, "#{@member['email']}")
   redirect_to signup_url
  else
   redirect_to welcome_url
  end
 end

 def welcome
  if member?
   @member = current_member
   # ## Check for nonmember records to convert to confirmations
   convert_non_member_approvals( NonMember.find(:first, :conditions => ["email = ?", @viewer.email ]) )
   flash[:notice] = "Welcome to MeetingWave, #{@member.user_name}!"
   if private_mw?
     type=private_mw 
   else
     type=nil   
   end    
   MemberNotify.deliver_verified(@member,type)
   if mobile_request?
    redirect_to my_invites_url
   else
     if !private_mw?
      redirect_to :controller => 'get_started', :action => 'step1', :eventid => params[:eventid],:meeting_id => params[:meeting_id]
     else
      email_checker 
     end    
   end
  else    
   flash[:notice] = "Sorry, but the email verification link you followed was incorrectly formatted or expired.  Please check the link and try again or just login below."
   redirect_to signup_url
  end
 end

  #~ def email_checker
    #~ eid = current_member.email.split('@')
    #~ univ = University.find(:first,:conditions => ["url = ?",@univ_account]).email_domains.map{|x| x.domain }
    #~ puts univ.inspect
    #~ if univ.include?(eid[1])
      #~ redirect_to my_invites_url
    #~ else
      #~ redirect_to :controller => 'invitations', :action => 'domain_verification'
    #~ end
  #~ end
  
  def email_checker
    if private_mw?
      eid = current_member.email.split('@')
      univ = University.find(:first,:conditions => ["url = ?",@univ_account]).email_domains.map{|x| x.domain }
      puts univ.inspect
      if univ.include?(eid[1])
        redirect_to :controller => 'get_started', :action => 'step1'
      else
        acemail = current_member.account_emails.find(:first,:conditions => ["university_name = ?",@univ_account])
        if !acemail.nil? &&  acemail.university_name == @univ_account && acemail.verified == true
          redirect_to :controller => 'get_started', :action => 'step1'
        else
          redirect_to :controller => 'invitations', :action => 'domain_verification'
        end
      end
    else
        redirect_to :controller => 'invitations', :action => 'myinvitations'      
    end
  end
  
 def welcome_with_response
  if member?
   @member = current_member
   # ## Check for nonmember records to convert to confirmations
   convert_non_member_approvals(NonMember.find(:first, :conditions => ["security_token = ?", params[:non_member_key] ]) )
   redirect_to(pre_verified_response_url(:id => params[:id], :response => params[:response]))
  else
   flash[:notice] = "Sorry, but the email verification link you followed was incorrectly formatted or expired.  Please check the link and try again or just login below."
   redirect_to signup_url
  end
 end


 def who_auto_complete
  re = Regexp.new(params[:who], Regexp::IGNORECASE)
  all_contacts = current_member.all_contacts
  @contacts = all_contacts.select { |contact| (contact.respond_to?(:email) && re.match(contact.email)) || 
    (contact.respond_to?(:user_name) && re.match(contact.user_name)) || 
    (contact.respond_to?(:fullname) && re.match(contact.fullname)) }
  @contacts = @contacts[0..5] if @contacts.size > 5
  render :layout => false
 end

 def who_auto_complete_json
  re = Regexp.new(params[:keyword] || "", Regexp::IGNORECASE)
  all_contacts = current_member.all_contacts
  contacts = all_contacts.collect do |contact| 
   if (contact.is_a?(NonMember) && ( re.match(contact.email) || re.match(contact.user_name) ) )
    caption = ( (contact.fullname.blank? || contact.fullname == contact.user_name) ?   contact.user_name : "#{contact.fullname} (#{contact.user_name})" )
    {:caption => caption, :value => contact.email }
   elsif (contact.is_a?(Member) && re.match(contact.user_name) || re.match(contact.fullname))
    caption = ( contact.fullname.blank? ?   contact.user_name : "#{contact.fullname} (#{contact.user_name})" )
    {:caption => caption, :value => contact.id }
   else
    nil
   end
  end
  contacts.compact!
  contacts = contacts[0..10] if contacts.size > 10
  render :text => contacts.to_json
 end

 protected
 
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
    end
  end
  
 def dont_have_super_secret_password?
  value =  !(params[:recaptcha_response_field] == "U6C9fDlSvB7nHwmTak5RP")
  return value
 end

 def destroy(member)
  MemberNotify.deliver_delete(member)
  flash[:notice] = l(:member_delete_finished, "#{member['email']}")
  member.destroy()
 end

 def protect?(action)
  if ['user_name', 'signup', 'forgot_password'].include?(action)
   return false
  else
   return true
  end
 end

 # Generate a template member for certain actions on get
 def generate_blank
  case request.method
  when :get
   @member = Member.new
   render
   return true
  end
  return false
 end

 # Generate a template member for certain actions on get
 def generate_filled_in
  @member = session[:member]
  case request.method
  when :get
   @member.terms_of_service = '1'
   render
   return true
  end
  return false
 end

 def convert_non_member_approvals(non_member)
  return [] if non_member.nil?
  confirmations = []
  non_member.non_member_approvals.each do |non_member_approval|
   meeting = (non_member_approval.invitation.upcoming_meeting || non_member_approval.invitation.meetings.first)
   confirmations << Confirmation.create(:invitation_id => non_member_approval.invitation.id, 
    :member_id     => @member.id,
    :status_id     => Status[:approved].id,
    :invited_as    => non_member.email,
    :meeting_id    => meeting.id)

   MemberApproval.create(:invitation_id => non_member_approval.invitation.id, 
    :member_id => @member.id, 
    :notified => non_member_approval.notified, 
    :notified_date => non_member_approval.notified_date)

   non_member.messages.each { |message| message.recipients << @member }
   non_member.destroy
  end
  return confirmations
 end
 
 # This may not actually be needed anymore since we should never end up on an SSL page.
 def url_for(options) 
    options.merge!(:only_path => false) rescue nil
    url = super
    unless url.match("myaccount_post$|login$")
       url.gsub!("https", "http") 
    end
    return url
 end
 
 def force_login
  # session[:member].forget_me unless session[:member].nil?
  cookies.delete :auth_token   
  cookies.delete :ttb_user_name 
  session[:member] = nil    
 end
end
