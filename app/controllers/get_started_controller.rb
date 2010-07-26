class GetStartedController < ApplicationController

  layout 'get_started'
  before_filter :private_global

  def step1
    ##################################
    if current_member
      if params[:meeting_id]
         session[:m_id] = params[:meeting_id]
         params[:id] ||= params[:meeting_id]
         @meeting   = Meeting.find( params[:id] )
         @invitation = @meeting.invitation
        
        invitee = current_member
        @meeting =  Meeting.find(params[:id])
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
          #~ InvitationNotify.deliver_acceptance(@confirmation, message, url_invite)
          #~ InvitationNotify.deliver_acceptor(@confirmation)
        end
      end
      ##################################         
      return unless request.post?
      meeting_interests = params[:what].split(',')
      meeting_interests.each do |mi|
        current_member.member_profile.meeting_interests.create(:interest => mi) if current_member
      end
      redirect_to :action => 'step2'
    else
      redirect_to "/"
    end   
  end


  def step2
    if current_member
      return unless request.post?
      current_member.member_profile.current_city = params[:city]
      current_member.member_profile.current_state = params[:state]
      current_member.member_profile.current_country = params[:country]
      current_member.member_profile.save
      loc_for_meeting_interest = params[:city]
      if params[:state].blank?
        loc_for_meeting_interest << ", #{params[:country]}"
      else
        loc_for_meeting_interest << ", #{params[:state]}"
      end
      if current_member
        current_member.member_profile.meeting_interests.each do |mi|
          mi.time = 'Anytime'
          mi.location = loc_for_meeting_interest
          mi.save
        end
      end
      redirect_to :action => 'step3'
    else
      redirect_to "/"
    end       
  end
  
  def step3
    if current_member
      search_filter = SearchFilter.new(:start_date => Time.now,
                                      :city => current_member.member_profile.current_city,
                                      :state => current_member.member_profile.current_state,
                                      :country => current_member.member_profile.current_country,
                                      :radius => 50)
      #@meetings = invites_for_get_started(search_filter)
      #@invitations = @meetings.collect { |meeting|  meeting.invitation }.uniq
      
      #~ if !params[:where].nil? && !params[:where].blank?
        scity = search_filter.city if !search_filter.nil? and !search_filter.city.nil?
        scity = "new york" if !search_filter.nil? and search_filter.city.nil?
        puts scity
        r = ZipCode.find(:first,:select => "latitude,longitude",:conditions => ["city = ?",scity])
        rad = 50
        if !r.nil?
          sql = "SELECT dest.id,dest.zip,3956 * 2 * ASIN(SQRT( POWER(SIN((orig.latitude - dest.latitude) * pi()/180 / 2), 2) + COS(orig.latitude * pi()/180) * COS(dest.latitude * pi()/180) * POWER(SIN((orig.longitude -dest.longitude) * pi()/180 / 2), 2) )) as distance FROM zip_codes dest, zip_codes orig WHERE dest.id = orig.id and dest.longitude between #{r.longitude}-#{rad}/abs(cos(radians(#{r.latitude}))*69) and #{r.longitude}+#{rad}/abs(cos(radians(#{r.latitude}))*69) and dest.latitude between #{r.latitude}-(#{rad}/69) and #{r.latitude}+(#{rad}/69) LIMIT 4096"
          z = ZipCode.find_by_sql(sql)
          zcids = z.collect(&:id)
        end
      #~ else
        #~ zcids = ""
      #~ end
      zcids = "" if r.nil?
      @invitations = Invitation.search "#{search_filter.country}",:with => {:start_date => Time.now..Time.now.advance(:days => 1000),:is_public => 1,:deactivated => 0,:zip_code_id => zcids}, :without => {:purpose_id => 19},:conditions => {:university_name => @univ_account}, :order => :start_date, :sort_mode => :desc, :page => params[:page], :per_page => 10
      @inv = Meeting.find(:first,:conditions => ["id = ?",session[:m_id]])
      session[:m_id] = nil
      if @invitations.size.zero? and !@inv
        redirect_to :action => 'step3a'
      else
        render :action => 'step3b'
      end
    else
      redirect_to "/"
    end   
  end

  def invites_for_get_started(search_filter)
    search_filter.full_text_search({:page => (params[:page]||1), :use_invitation => true}, :include => SearchFilter::INVITATION_BROWSE_INCLUDES)   
  end

  def step3a
    return unless request.post?
    @invitation = Invitation.new(:inviter => current_member, 
                                 :is_public => true, 
                                 :name => params[:title],
                                 :description => params[:description],:university_name => params[:univname])
   
    # WHERE
    name = params[:location_name] || params[:address]
    @address = Address.create(:name => name, 
      :address => params[:address], 
      :city => params[:city], 
      :state => params[:state], 
      :country => params[:country], 
      :kind => 'regular')
    @invitation.address = @address
    
    # WHEN
    offset = (params[:client_tz_offset] || '-18000').to_i
    if Time.now.isdst and not ["India", "China"].include?(params[:country])
      offset -= (60*60)
    end
    tz = TimeZone.mw_us_zones.find { |z| (z.utc_offset == offset) and (z.name != 'Arizona') and (z.name != 'Indiana') } 
    tz ||= TimeZone[offset]
    @invitation.time_zone = tz.name

    @invitation.recurrence_frequency = params[:invitation][:recurrence_frequency]

    date_str = params[:date]
    # start_time[hour] will be in the form "3 AM"
    start_hour, meridiem = params[:start_time][:hour].split(' ')
    start_time_string = "#{date_str} #{start_hour}:#{params[:start_time][:minute]} #{meridiem}"
    # end_time[hour] will be in the form "3 AM"
    end_hour, meridiem = params[:end_time][:hour].split(' ')
    end_time_string = "#{date_str} #{end_hour}:#{params[:end_time][:minute]} #{meridiem}"

    begin
      @invitation.start_time = Time.parse_with_timezone(start_time_string, @invitation.time_zone)
    rescue InvalidTimeStringException => e
      @invitation.start_time = nil
    end

    begin
      @invitation.end_time = Time.parse_with_timezone(end_time_string, @invitation.time_zone)
    rescue InvalidTimeStringException => e
      @invitation.end_time = nil
    end

    # Normally, we would ask them to fix this in validation code, but we're
    # trying to keep validation errors limited to client-side in this first
    # cut.
    if @invitation.end_time < @invitation.start_time
      @invitation.end_time = @invitation.start_time + 1.hour
    end
   
    # Defaults
    @invitation.purpose = Purpose::OTHER 
    @invitation.payment = Payment::FREE_OR_NA
    @invitation.activity = Activity::OTHER

    @invitation.draft_status = 'posted'
	if @invitation.save
		flash[:notice] = "Your Invite has been successfully posted!"
                   flash[:fb_connect_post] = "true" if(current_member.social_network_user)

    end
     if(context?(:social_network))
        url = facebook_invite_friends_to_invite_url(:id => @invitation.id, :canvas => true, :only_path => false) #this has been change ont he routing level.
        render :text => "<script> parent.location = '#{url}' </script> "
    else
	redirect_to  my_invites_url(:invitation_id => @invitation.id)
    end
  end

 	def get_invitation
	   params[:id] ||= params[:meeting_id]
	   @meeting   = Meeting.find( params[:id] )
	   @invitation = @meeting.invitation
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


end
