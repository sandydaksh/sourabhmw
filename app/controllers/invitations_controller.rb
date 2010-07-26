class InvitationsController < ApplicationController      
#~ require 'will_paginate'
  before_filter :private_global
  auto_complete_for :meetinginterest, :interest
  
  layout 'invitations'
	
  helper :member_profiles
  helper :addresses
  helper :search_filters
  helper :guest_response  
  helper :browse
  
  before_filter :url_check, :except => [:do_verify]
  before_filter :login_required, :except => [:emaildomainverify,:testemail,:code_image,:do_verify,:domain_verification,:verify_alumini,:auto_complete_for_find_meeting,:sandy, :index, :index2,  :home_page_map, :content, :show, :search, :non_member_view, :set_location, :update_guest_response, :not_found, :facebook_about_page, :set_classic, :set_mobile ,:meeting_today_or_tomorrow]
  before_filter :get_invitation, :only => [ :show, :update_guest_response ]
  before_filter :protect_private_invites, :only => [ :show ]
  before_filter :setup_meeting, :only => [ :update_guest_response ]
  
  verify :method => :delete, :only => [ :destroy ], :redirect_to => { :action => :index }
  
  prepend_before_filter :redirect_if_member , :only => :index

  def set_classic 
    session[:user_selected_classic] = true
    redirect_to home_url
  end
  
  def code_image 
    @image_data = University.find(params[:id]) 
    @image = @image_data.binary_data 
    send_data (@image, :type => @image_data.content_type, :filename => @image_data.filename, :disposition => 'inline')  
  end 
  
  def emaildomainverify
    MemberEmail.connection.execute("update member_emails set verified = 1 where id = #{params[:id]}")
    redirect_to "/"
  end
  
  ### Funtion for meeting type autocompleter text field.
	def auto_complete_for_find_meeting
		what = params[:find][:meeting]
		if what.empty?  
			render :text => "Please type something."
		end
		@matches = MeetingInterest.find(:all, :select => "distinct interest", :conditions =>["interest LIKE ?","#{what}%"],:limit => 10 )
		if @matches.empty?
			render :inline => "<%= content_tag(:ul, content_tag(:li, 'No matches found.')) %>"
		else
			vulgur_words = ["fuck","sex","fuck off","fuck of","fuck off fuck u all","fuck u all"]
			@result = []
			@matches.each do |match|
				@result << match.interest if !vulgur_words.include?(match.interest)
			end
			render :inline => "<%= content_tag(:ul, @result.map { |org| content_tag(:li, h(org.slice(0..20))) }) %>"
		end
	end  

  def set_mobile
    session[:user_selected_classic] = false
    redirect_to home_url
  end

  def content
    render :file => "#{RAILS_ROOT}/public/xml/content.xml"
  end

  ## Fuction for displaying home page contents.
  def index
    puts"--------------------------------------------"
    puts request.env["HTTP_REFERER"]
    
    if params[:pritop]
      session[:member] = Member.authenticate_public_private_transition(params['pritop'])
      if session[:member]
        if params[:remember] == "1"
          session[:member].remember_me
          cookies[:auth_token] = { :value => session[:member].remember_token , :expires => session[:member].remember_token_expires_at }  
        end          
        cookies[:ttb_user_name] = session[:member].fullname    
        redirect_to :action => "myinvitations"
      end
    elsif params[:pubtop]
      session[:member] = Member.authenticate_public_private_transition(params['pubtop'])
      if session[:member]
        if params[:remember] == "1"
          session[:member].remember_me
          cookies[:auth_token] = { :value => session[:member].remember_token , :expires => session[:member].remember_token_expires_at }  
        end          
      cookies[:ttb_user_name] = session[:member].fullname    
      redirect_to :action => "myinvitations"
      end
    else
      @search_filter = SearchFilter.new
      @no_sign_in = true
      response.time_to_live = 4.hours
      if private_mw?
        @todays_invites = LookUp::invites_for_todays_upcoming_on_home_private_label(private_mw)
        puts @todays_invites.length
        today_ids = @todays_invites.map{|x| x.id}
        @tomorrows_invites = LookUp::invites_for_tomorrows_upcoming_on_home_private_label(private_mw,today_ids)
        puts @tomorrows_invites.length
        tomorrow_ids = @tomorrows_invites.map{|x| x.id} if @tomorrows_invites
      else  
        @todays_invites = LookUp::invites_for_todays_upcoming_on_home
        today_ids = @todays_invites.map{|x| x.id}
        @tomorrows_invites = LookUp::invites_for_tomorrows_upcoming_on_home(today_ids)
        tomorrow_ids = @tomorrows_invites.map{|x| x.id} if @tomorrows_invites
      end
      render :layout => 'myhome' unless mobile_request?      
    end
  end
  
  def domain_verification
    @err = []
    @account = AccountEmail.new    
    if request.post?
      @account = AccountEmail.new(params[:account_email])
      @account.member_id = current_member.id
      @account.verification_code = AccountEmail.random_string(10)
      if !params[:account_email][:email].nil?
        eid = params[:account_email][:email].split('@')
        univ = University.find(:first,:conditions => ["url = ?",@univ_account]).email_domains.map{|x| x.domain }
        if !univ.include?(eid[1])
          @err << "Please enter a valid University email address."
        end
      end  
      
      if params[:account_email][:email].nil? || params[:account_email][:email].blank? || params[:account_email][:email].empty?
        @err << "Please enter a valid email address."
      end
      
      if @err.empty?
        if @account.save
          MemberNotify.deliver_account_verification(request.host,@account)
          flash[:mailsent] = "Mail Sent"
        end  
      end
    end  
    render :layout => 'myhome'
  end
  
  def testemail
    @account = AccountEmail.find_by_id(1)
    MemberNotify.deliver_account_verification(request.host,@account)
  end
  
  def do_verify
    user = Member.find(:first,:conditions => ["id = ?",params[:id]])
    ac = AccountEmail.find(:first,:conditions => ["member_id=? and verification_code=? and university_name = ?",params[:id],params[:key],private_mw])
    ac.verified = 1
    ac.save
    #~ AccountEmail.connection.execute("update account_emails set verified=1 where id=#{ac.id}")
    #~ acv = AccountEmail.find(:first,:conditions => ["member_id=? and verification_code=? and university_name = ?",params[:id],params[:key],private_mw])
    if ac.verified
      session[:member] = Member.authenticate_public_private_transition(user.email)
      if session[:member]
        if params[:remember] == "1"
          session[:member].remember_me
          cookies[:auth_token] = { :value => session[:member].remember_token , :expires => session[:member].remember_token_expires_at }  
        end          
        cookies[:ttb_user_name] = session[:member].fullname    
      end
    end
    #~ redirect_to "/invitations/myinvitations"
    redirect_to :controller => 'get_started', :action => 'step1'
  end

  def verify_alumini
    if request.post?
      val = Alumini.find(:first,:conditions => ["user_name = ? and password = ?",params[:alumini][:user_name],params[:alumini][:password]])
      if !val.nil?
        session[:alumini] = val.id
        session[:alumini_id] = val.id
        if !val.user_id.nil?
          redirect_to :action => :index
        else
          session[:alumini] = nil
          redirect_to "/member"
        end
      else
        flash[:notice] = "Authentication Failed."
        render :layout => 'verifyalumni'      
      end
    else
      render :layout => 'verifyalumni'      
    end
  end

  ## Funtion for displaying the today's or tomorrow's meetings after clicking from home page.
  def meeting_today_or_tomorrow
    @search_filter = SearchFilter.new
    @search_filter.start_time = Time.now.utc
    if params[:day].to_i == 1
		 @invites_list = LookUp::invites_for_todays_meeting_list
		 @for="TODAY'S MEETING LIST"
     @day = "today."
	  elsif params[:day].to_i == 2
      @invites_list = LookUp::invites_for_tomorrows_meeting_list
      @day = "tomorrow."
      @for="TOMORROW'S MEETING LIST"
    end
    @invitations = @invites_list.paginate :page => params[:page], :per_page => 10 if !@invites_list.nil?
    if params[:day] and (params[:day].to_i == 1 || params[:day].to_i == 2)
      render :layout => 'new_super_search'
    else
      redirect_to home_url
    end
  end
  
  def facebook_about_page
    render :action => "about_page_fbml", :layout => "about_page_fbml"
  end

  def not_found
      render :layout => false
  end   

  #~ def myinvitations
    #~ @upcoming_near_me = []
    #~ @current_city = current_member.member_profile.current_city 
    #~ @current_state = current_member.member_profile.current_state 
    #~ @current_country = current_member.member_profile.current_country 
    
   #~ if( @current_city.blank? && @current_state.blank? && @current_country.blank? )
    #~ @current_city = "New York" 
    #~ @current_state = "NY" 
    #~ @current_country = "United States" 
   #~ end
   
    #~ @watching = @viewer.future_confirmations('SAVED') rescue []
    #~ @watching.flatten!
    #~ @watching = @watching.sort_by{ |conf| conf.meeting.start_time }
    #~ @member_profile = current_member.member_profile
    #~ render :layout => 'myinvitations' unless (check_render_facebook("myinvitations") or mobile_request?)
  #~ end
  
  ## New function for displaying myinvitations page.
  def myinvitations
    @search_filter = SearchFilter.new
    @search_filter.start_time = Time.now.utc
    @upcoming_near_me = []
    @current_city = current_member.member_profile.current_city 
    @current_state = current_member.member_profile.current_state 
    @current_country = current_member.member_profile.current_country 
    
    if( @current_city.blank? && @current_state.blank? && @current_country.blank? )
      @current_city = "New York" 
      @current_state = "NY" 
      @current_country = "United States" 
    end    
    @member_profile = current_member.member_profile
    if params[:near]
      @invitations = Invitation.search "#{@current_city} #{@current_state} #{@current_country}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0}, :without => {:purpose_id => 19},:conditions => {:university_name => @univ_account}, :order => :id, :sort_mode => :desc
      @invitations = @invitations.paginate :page => params[:page], :per_page => 10 if !@invitations.nil?
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    elsif params[:created]
      @invitations = current_member.posted_invites_public_private(@univ_account).collect { |i| (i.upcoming_meeting rescue nil)  }.flatten
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave_meetings'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    elsif params[:accepted]
      @invitations = current_member.future_confirmations('ACCEPTED',@univ_account).collect { |c| c.meeting}  
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave_meetings'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    elsif params[:received]
      @invitations = current_member.received_invites(@univ_account) #Returns Invitations.
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave_meetings'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    elsif params[:confirmed]
      @invitations = current_member.confirmed_as_guest(@univ_account) #Returns Meetings.
      #~ @invitations << current_member.confirmed_posted
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave_meetings'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    elsif params[:watching]
      @watching = current_member.future_confirmations('SAVED',@univ_account) rescue []
      @watching.flatten!
      @watching = @watching.sort_by{ |conf| conf.meeting.start_time }
      @invitations = @watching
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave_widget'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    elsif params[:archive]
      setup_archived_meetings
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave_archive'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    elsif params[:all]
      @invitations = all_my_meetings
      render :update do |page|
          page.replace_html "maincontent", :partial => 'mymeetingwave_meetings'
          page.replace_html "inviteid", :partial => 'invitations_tabs'
      end
    else
      @invitations = Invitation.search "#{@current_city} #{@current_state} #{@current_country}",:with => {:start_date => Time.now.utc..Time.now.utc.advance(:days => 1000),:is_public => 1,:deactivated => 0}, :without => {:purpose_id => 19},:conditions => {:university_name => @univ_account}, :order => :id, :sort_mode => :desc
      render :layout => false
    end
    
  end  
  
   def all_my_meetings
    @confirmed = current_member.confirmed_as_guest(@univ_account) # Returns Meetings
    @received  = current_member.received_invites(@univ_account)  # Returns Invitations
    @posted    = current_member.posted_invites_public_private(@univ_account).collect { |i| (i.upcoming_meeting rescue nil)  }.flatten # Returns Meetings   
    @confirmed_posted = current_member.confirmed_posted(@univ_account)
    @confirmed << @confirmed_posted
    @accepted  = current_member.future_confirmations('ACCEPTED',@univ_account).collect { |c| c.meeting}  
    @my_invitations = [@posted, @confirmed, @accepted, @received ].flatten.uniq
    @my_invitations.sort do |a, b| 
      a_mtg = (a.is_a?(Meeting) ? a : (a.upcoming_meeting rescue a))
      b_mtg = (b.is_a?(Meeting) ? b : (b.upcoming_meeting rescue b))
      a_mtg.start_time_local <=> b_mtg.start_time_local
    end
    return @my_invitations
  end
 
  def setup_archived_meetings
    @archived_buckets = { }
    @posted_meetings = @viewer.past_posted_invites(@univ_account).map(&:past_meetings).flatten.sort_by(&:start_time).reverse  
    @posted_meetings = @posted_meetings.delete_if { |pm| pm.confirmed_invitees.size.zero? }
    @posted_meetings.each { |m| @archived_buckets[m] = "archive-posted" }
    @attended_meetings = @viewer.past_attended_meetings(@univ_account).sort_by(&:start_time).reverse 
    @attended_meetings.each { |m| @archived_buckets[m] = "archive-attended" }
    @archived_meetings = (@posted_meetings + @attended_meetings).sort { |a, b| b.start_time <=> a.start_time }
  end
  
  # This needs to be blown away when the above is true or a confirmation is created
  def show_cache_key
    CachingObserver.show_invite_key(current_member, params)
  end
  
  helper_attr :show_cache_key

  def show
    @m_idd=params[:meeting_id]
    eve =  Invitation.find_by_id(params[:id])
    
    if eve.university_name == 'public'
      @search_filter = SearchFilter.new
      @search_filter.start_time = Time.now.utc
      #session[:return_to] = nil
      when_fragment_expired(show_cache_key) do
        # This should be refactored
        redirect_to(show_invite_url(:id => @invitation.id, :meeting_id => @invitation.meetings.last.id)) and return true if( @invitation.deactivated? and params[:meeting_id].to_i == 0  )
        render(:file => "#{RAILS_ROOT}/public/404.html", :status => "404 Not Found") and return unless @invitation.inviter

       begin
        setup_meeting()
       rescue => e
        logger.error("Error finding meeting: #{e}.  Will redirect to not_found.")
        (redirect_to not_found_url and return false)
      end
      
        @member = current_member
        @address = @invitation.address      

        if(params[:meeting_id].nil? || (params[:meeting_id] == 'next')) # TODO: Do we need this? setup meeting does this 06/08 -dave
          @meeting = @invitation.upcoming_meeting
          if @meeting.nil?
            @meeting = @invitation.most_recent_meeting
          end
          @meeting_selected = false
        else
          @meeting = @invitation.meetings.find(params[:meeting_id])
          @meeting_selected = true
        end
        @confirmation = @meeting.confirmations.find_by_member_id(@member.id) unless @member.nil?

        if(@member and @member == @invitation.inviter)
          (@guest_list, @outstanding_rsvps) = @invitation.guest_responses_for_inviter(@meeting)
        else
          @guest_responses = @invitation.guest_responses(@member, @meeting)
        end
        query = @invitation.name
        @sim_meetings = Invitation.search(query.split.collect{ |c| "%#{c.downcase}%" },:conditions => {:university_name => @univ_account},:width => {:is_public => 1,:deactivated => 0}, :page => params[:page], :per_page => 100 )
        @reminder = Reminder.find_by_invitation_id_and_member_id(@invitation.id, @member.id) unless @member.nil?   
      end
      unless (check_render_facebook('invitations') or mobile_request?)
        render(:layout => 'show_invite') 
      end
    else
     
      acemail = current_member.account_emails.find(:first,:conditions => ["university_name = ?",eve.university_name]) if current_member
      if current_member and !acemail.nil? and acemail.university_name == private_mw
        @search_filter = SearchFilter.new
        @search_filter.start_time = Time.now.utc
        #session[:return_to] = nil
        when_fragment_expired(show_cache_key) do
          # This should be refactored
          redirect_to(show_invite_url(:id => @invitation.id, :meeting_id => @invitation.meetings.last.id)) and return true if( @invitation.deactivated? and params[:meeting_id].to_i == 0  )
          render(:file => "#{RAILS_ROOT}/public/404.html", :status => "404 Not Found") and return unless @invitation.inviter

         begin
          setup_meeting()
         rescue => e
          logger.error("Error finding meeting: #{e}.  Will redirect to not_found.")
          (redirect_to not_found_url and return false)
        end
        
          @member = current_member
          @address = @invitation.address      

          if(params[:meeting_id].nil? || (params[:meeting_id] == 'next')) # TODO: Do we need this? setup meeting does this 06/08 -dave
            @meeting = @invitation.upcoming_meeting
            if @meeting.nil?
              @meeting = @invitation.most_recent_meeting
            end
            @meeting_selected = false
          else
            @meeting = @invitation.meetings.find(params[:meeting_id])
            @meeting_selected = true
          end
          @confirmation = @meeting.confirmations.find_by_member_id(@member.id) unless @member.nil?

          if(@member and @member == @invitation.inviter)
            (@guest_list, @outstanding_rsvps) = @invitation.guest_responses_for_inviter(@meeting)
          else
            @guest_responses = @invitation.guest_responses(@member, @meeting)
          end
          query = @invitation.name
          @sim_meetings = Invitation.search(query.split.collect{ |c| "%#{c.downcase}%" },:conditions => {:university_name => @univ_account},:width => {:is_public => 1,:deactivated => 0}, :page => params[:page], :per_page => 100 )
          @reminder = Reminder.find_by_invitation_id_and_member_id(@invitation.id, @member.id) unless @member.nil?   
        end
        unless (check_render_facebook('invitations') or mobile_request?)
          render(:layout => 'show_invite') 
        end        
      else
        redirect_to "http://#{eve.university_name}.#{request.host}/member" if !request.host.match(eve.university_name)
        redirect_to "http://#{request.host}/member" if request.host.match(eve.university_name)
      end
    end
  end
  
  def private
    render :layout => 'invitations'    
  end

  def non_member_view
    @invitation   = Invitation.find( params[:id], :include => [:meetings, {:address => [:airport, :zip_code]}, :inviter, :activity, :payment, :purpose] ) rescue (redirect_to not_found_url and return false)
    @meeting = (@invitation.upcoming_meeting || @invitation.meetings.first)
    unless @non_member = NonMember.find_by_security_token(params[:security_token])
      redirect_to :action => 'show', :id => params[:id]
      return
    end
    @guest_responses = @invitation.guest_responses(@member, @meeting)
    render :layout => 'invitations'
  end
         
  def pre_verified_response
    @invitation   = Invitation.find( params[:id], :include => [:meetings, {:address => [:airport, :zip_code]}, :inviter, :activity, :payment, :purpose] ) rescue (redirect_to not_found_url and return false)
    @meeting = (@invitation.upcoming_meeting || @invitation.meetings.first)
   redirect_to(show_invite_url(@invitation) ) and return unless(current_member.confirmation_for(@invitation))
    @invite_response = params[:response]
    @member = current_member
    @guest_responses = @invitation.guest_responses(@member, @meeting)
    # When they click Accept/Decline, they should go to their invites page.  
    # Otherwise they would be returned to this page.
    session[:return_to] = my_invites_url  
    render :layout => 'invitations'
  end
  
  def update_guest_response
    @guest_responses = @invitation.guest_responses(@member, @meeting)
    @confirmation = current_member.confirmation_for(@meeting)
    @member = current_member
  end
  
  # This action forces a login so that a user can make a response to this invite.
  def respond
    flash[:notice] = "Click the ATTEND button to let the invitor know you'd like to attend."
    redirect_to show_invite_url(:id => params[:id])
  end

  def confirm_delete
    @invitation = Invitation.find(params[:id])
    @invitees = ( @invitation.confirmed_invitees + @invitation.all_invited_members )
    @invitees.uniq!
	unless request.post?
		render :layout => "show_invite" unless mobile_request?
		return
	end
    if member? and @viewer.owner(@invitation)
		members = (params[:members].blank? ? [] : Member.find(params[:members]))
		non_members = (params[:non_members].blank? ? [] : NonMember.find(params[:non_members]) )
		@invitation.destroy
		people_to_notify = (members + non_members)
	    unless people_to_notify.blank?
			InvitationNotify.deliver_inviter_destroyed(@invitation, people_to_notify)
			logger.error("Sending cancel notification to members: #{members.collect(&:user_name).join(", ")}")
			logger.error("Sending cancel notification to non_members: #{non_members.collect(&:user_name).join(", ")}")
			flash[:notice] = "Your Invite has been deleted and notifications have been sent to the selected invitees."
		else
			flash[:notice] = "Your Invite has been deleted."
		end
		redirect_to  my_invites_url
	else
      flash[:notice] = "You are not authorized for that action."
      redirect_to upcoming_url
	end
  end

  def destroy
    @invitation = Invitation.find( params[:id] ) rescue (redirect_to not_found_url and return false)
    if member? and @viewer.owner(@invitation)
      @invitation.notify_invitees
      @invitation.destroy
      redirect_to my_invites_url
    else
      flash[:notice] = "You are not authorized for that action."
      redirect_to upcoming_url
    end
  end

  def set_location
    loc = TextLocation.new(params[:value])
    @geoip_location.zip     = (loc.zip rescue '')
    @geoip_location.city    = loc.city
    @geoip_location.state   = loc.state
    @geoip_location.country = loc.country
    @meetings_near_me = Invitation.find_near_location(@geoip_location)
  end

  def sethomebase
    @member_profile = current_member.member_profile	
    @member_profile.update_attributes(params[:member_profile])
    @member_profile.save
    redirect_to :action => 'myinvitations'
  end

  def flag
    f = Flagging.create!(params[:flagging])
    f.invitation.flag!
    render :update do |page|
      page.remove "flag-form"
      page.remove "flag-link"
      page.show "flag-thanks"
    end
  end

  protected
  def redirect_if_member
    if member? || ( ( try_set_facebook_session && fb_user and member?) rescue false )
      redirect_to my_invites_url
      return false
    end
  end
  
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
      session[:university] = private_mw
      #render :action => :verify_alumini,:layout => "verifyalumni" unless !session[:university].nil?
    end
  end
  
  def get_invitation
    begin
      @invitation = Invitation.find( params[:id], :include => [{:meetings => :confirmations}, 
          {:address => [:airport, :zip_code]}, 
          :inviter, 
          :activity, 
          :payment, 
          :purpose] ) 
    rescue => e
      logger.error("Error finding invite with id #{params[:id]}: #{e}.  Will redirect to not_found.")
      (redirect_to not_found_url and return false)
    end
  end
  
 
  
  def setup_meeting
    if params[:meeting_id] == 'next'
      if( @invitation.deactivated? )
        redirect_to(show_invite_url(:id => @invitation.id, :meeting_id => @invitation.meetings.last.id)) and return true
      else
        @meeting = @invitation.upcoming_meeting
      end
    else
      @meeting = Meeting.find(params[:meeting_id])
    end
    @confirmation = @meeting.confirmations.find_by_member_id(current_member.id) unless current_member.blank?
  end

  def protect_private_invites
    return true unless @invitation.is_private?
    if current_member.nil?
      session[:return_to] = request.request_uri
      flash[:notice] = "You must be logged-in to view this invite."
      redirect_to login_url
      return false
    else
      unless ((current_member == @invitation.inviter) or (current_member.invited_to(@invitation)))
        redirect_to private_invite_url
        return false
      end
    end
    return true
  end
  
  
  

  def error
    # wrapper to provide view for invitation retrieval errors
  end
  

end
