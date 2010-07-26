class RsvpController < ApplicationController

  helper :invitations, :guest_response, :member_profiles
  before_filter :login_required
  before_filter :get_confirmation, :only => [  :approve, :reject, :approve_reject]
  before_filter :get_invitation, :only => [ :accept, :decline, :attend ]

  # This is processed when a user clicks the "ACCEPT" button on an invite that
  # they have been invited to.
  #  Invitor: I want you to come to this event.
  #  Invitee: Cool, I'll be there. 
  def accept
    return accept_or_decline(:accept)
  end

  # This is processed when a user clicks the "DECLINE" button on an invite that
  # they have been invited to.
  #  Invitor: I want you to come to this event.
  #  Invitee: I can't make it. 
  def decline
    return accept_or_decline(:decline)
  end

  # This is processed when a user clicks the "ACCEPT" button on an invite that
  # they have *not* been invited to.
  #  Random Person: I want to come to this!
  #~ def attend
    #~ puts "=================================================="
    #~ puts params[:img_txt]
    #~ puts params[:cap_words]
    #~ invitee = current_member
    #~ @meeting =  Meeting.find(params[:id])
    
    #~ # Get the confirmation for this meeting and user.  Hopefully, we either build a new one or we 
    #~ # find one with a satus of 'Saved'--that is, one where the user has not already accepted.
    #~ @confirmation = @meeting.confirmations.find_by_member_id(invitee.id) 
    #~ if @confirmation.nil?
      #~ @confirmation = @meeting.confirmations.build(:status_id => Status[:accepted].id, :member_id => invitee.id, :invitation_id => @meeting.invitation_id)
    #~ end
        
    #~ if @confirmation.new_record? or @confirmation.status == Status[:saved]
      #~ @confirmation.status = Status[:accepted] 
      #~ @invitation.confirmations << @confirmation
      #~ invitee.confirmations << @confirmation
      #~ if @confirmation.save
        #~ url_invite = show_invite_url(:id => @invitation.id, 
                                     #~ :meeting_id => (@meeting.id rescue nil),
                                     #~ :member_id => @invitation.inviter.id, 
                                     #~ :key => @invitation.inviter.generate_security_token) 
        #~ message = message_handler(@meeting,[@invitation.inviter])
        #~ InvitationNotify.deliver_acceptance(@confirmation, message, url_invite)
        #~ InvitationNotify.deliver_acceptor(@confirmation)
        
         #~ if @invitation.inviter 
           #~ if !current_member 
             #~ if !@invitation.hidden_user_name.nil? 
              #~ uname = @invitation.hidden_user_name.private_name
             #~ else 
              #~ uname = @invitation.inviter.user_name
             #~ end 
           #~ else 
             #~ if @invitation.inviter.id == current_member.id 
              #~ uname = @invitation.inviter.user_name
             #~ else 
               #~ if current_member.was_approved(@invitation.upcoming_meeting) 
                #~ uname = @invitation.inviter.user_name
               #~ else 
                #~ if !@invitation.hidden_user_name.nil?
                  #~ uname = @invitation.hidden_user_name.private_name
                #~ else
                  #~ uname = @invitation.inviter.user_name
                #~ end                              
               #~ end 
             #~ end 
           #~ end 
         #~ end 
        
        #~ msg = "We've notified #{uname} that you want to attend #{@invitation.name}.  You will get an email when they have responded."

		#~ if(!mobile_request? and (current_member.member_profile.pretty_empty? rescue true))
		  #~ msg << "<br/><br/>  Please <a href='#{my_profile_url(:just => 'accepted')}'>complete your profile</a>, so that #{@invitation.inviter.username} can learn a little more about you before you meet."
		#~ end

      #~ end
    #~ else
      #~ msg = existent_confirmation_message(@confirmation.status)
    #~ end
     
    #~ if request.xhr?
      #~ flash.now[:notice] = msg
    #~ else
      #~ flash[:notice] = msg
      #~ redirect_to show_invite_url(:id => @invitation.id, :meeting_id => (@meeting.id rescue 'next'))
      #~ return
    #~ end
  #~ end
  
  def attend
    invitee = current_member
    @meeting =  Meeting.find(params[:id])
    
    # Get the confirmation for this meeting and user.  Hopefully, we either build a new one or we 
    # find one with a satus of 'Saved'--that is, one where the user has not already accepted.
    @confirmation = @meeting.confirmations.find_by_member_id(invitee.id) 
    if @confirmation.nil?
      @confirmation = @meeting.confirmations.build(:status_id => Status[:accepted].id, :member_id => invitee.id, :invitation_id => @meeting.invitation_id)
    end
    
    if params[:img_txt] == params[:cap_words]
    if @confirmation.new_record? or @confirmation.status == Status[:saved]
      @confirmation.status = Status[:accepted] 
      @invitation.confirmations << @confirmation
      invitee.confirmations << @confirmation
      if @confirmation.save
        url_invite = show_invite_url(:id => @invitation.id, 
                                     :meeting_id => (@meeting.id rescue nil),
                                     :member_id => @invitation.inviter.id, 
                                     :key => @invitation.inviter.generate_security_token) 
        message = message_handler(@meeting,[@invitation.inviter])
        InvitationNotify.deliver_acceptance(@confirmation, message, url_invite)
        InvitationNotify.deliver_acceptor(@confirmation)
        
         if @invitation.inviter 
           if !current_member 
             if !@invitation.hidden_user_name.nil? 
              uname = @invitation.hidden_user_name.private_name
             else 
              uname = @invitation.inviter.user_name
             end 
           else 
             if @invitation.inviter.id == current_member.id 
              uname = @invitation.inviter.user_name
             else 
               if current_member.was_approved(@invitation.upcoming_meeting) 
                uname = @invitation.inviter.user_name
               else 
                if !@invitation.hidden_user_name.nil?
                  uname = @invitation.hidden_user_name.private_name
                else
                  uname = @invitation.inviter.user_name
                end                              
               end 
             end 
           end 
         end 
        msg = "We've notified #{uname} that you want to attend #{@invitation.name}.  You will get an email when they have responded."
		if(!mobile_request? and (current_member.member_profile.pretty_empty? rescue true))
		  msg << "<br/><br/>  Please <a href='#{my_profile_url(:just => 'accepted')}'>complete your profile</a>, so that #{uname} can learn a little more about you before you meet."
		  
		  
		end
    end
    else
      msg = existent_confirmation_message(@confirmation.status)
    end
      if request.xhr?
        flash.now[:notice] = msg
        render :update do |page|
            page.replace_html "sandy#{@meeting.invitation_id}", :partial => 'captch_text1'
            page.visual_effect :highlight,"sandy#{@meeting.invitation_id}"
        end
      else
        flash[:notice] = msg
        redirect_to show_invite_url(:id => @invitation.id, :meeting_id => (@meeting.id rescue 'next'))
        return
      end
    else
      @txemsg = "Captcha words does not match."
      render :update do |page|
          page.replace_html "sandy#{@meeting.invitation_id}", :partial => 'captch_text'
      end
    end
    
  end  
  
  def add_todo_popup                                                        #for add todo popup on matching page.
    render :update do |page|
      page.replace_html "nospam",:partial => "shared/nospam"
    end
  end  
  
  def capload
      @cimg = CaptchaImage.find(:first, :order => "RAND()", :limit => 1)
      @mid = params[:id]
      render :update do |page|
          page.replace_html "cap#{params[:id]}", :partial => 'cap'
      end
  end
    
  def capref
      @cimg = CaptchaImage.find(:first, :order => "RAND()", :limit => 1)
      @mid = params[:id]
      render :update do |page|
          page.replace_html "cap#{params[:id]}", :partial => 'capref'
      end
  end
 
  def approve_reject
    approve_or_reject(params[:app_rej].to_sym)
  end

  def quick_approve_reject

	@invitee = Member.find(params[:invitee_id])
	@meeting = Meeting.find(params[:meeting_id])
	@invitation = @meeting.invitation

    if current_member.owner(@meeting.invitation)
      new_status = ((params[:new_status]  == 'Approve') ? :confirmed : :declined)
	  # Find or create a confirmation for this meeting & user.  
	  @confirmation = @meeting.confirmations.find_by_member_id(@invitee.id) 
	  if @confirmation.nil?
		@confirmation = @meeting.confirmations.build(:status_id => Status[new_status].id, :member_id => @invitee.id, :invitation_id => @meeting.invitation_id)
	  end
      @confirmation.status = Status[new_status]
      if @confirmation.save
        url = show_invite_url( :id => @meeting.invitation.id, :meeting_id => @meeting.id, :member_id => @confirmation.member.id, :key => @confirmation.member.generate_security_token) 
        email = "deliver_#{params[:new_status] == 'Approve' ? 'acceptance_approved' : 'acceptance_declined'}".to_sym
        @message = message_handler(@confirmation.meeting, [@confirmation.member])
        InvitationNotify.send(email, @confirmation, @message, url)
        msg = "Thanks!  We've sent a notification email to #{@confirmation.member.user_name}."
		(@guest_list, @outstanding_rsvps) = @invitation.guest_responses_for_inviter(@meeting)
		even_or_odd = ((@guest_list.size % 2) == 0 ? 'odd' : 'even')
      end
	end

	render :update do |page|
	  page.remove("outstanding_#{params[:invitee_id]}")
	  page.replace_html('flash', msg)
	  page.show('flash')
	  page.insert_html(:bottom, 'guest_list_table', guest_response_sidebar_row(@meeting, @invitee, even_or_odd))

	  if @outstanding_rsvps.blank?
		  page.hide('outstanding_rsvps') 
		  page.show('no_outstanding_rsvps') 
      end

	  unless @guest_list.blank?
		  page.hide('no_guest_list') 
		  page.show('guest_list') 
	  end

    end

  end


  # This is similar to "starring" an email or "bookmarking" a web page.  The
  # viewer sees an interesting event and isn't ready to attend, but wants to
  # hang onto it for future reference.
  #  Random Person: This looks cool, but first I'll have to check my calendar. 
  def watch
    @meeting = Meeting.find(params[:id])
    @invitation = @meeting.invitation
    @invitee = current_member
    
    # Find or create a confirmation for this meeting & user.  
    @confirmation = @meeting.confirmations.find_by_member_id(@invitee.id) 
    if @confirmation.nil?
      @confirmation = @meeting.confirmations.build(:status_id => Status[:saved].id, :member_id => @invitee.id, :invitation_id => @meeting.invitation_id)
    end
        
    if @confirmation.new_record? 
      @invitation.confirmations << @confirmation
      @invitee.confirmations << @confirmation
      @confirmation.save
      msg = "The invitation has been added to the list of invitations you're watching."
    else
      msg = existent_confirmation_message(@confirmation.status)
    end
    if request.xhr?
      flash.now[:notice] = msg
    else
      flash[:notice] = msg
      redirect_to show_invite_url(:id => @invitation.id, :meeting_id => (@meeting.id rescue 'next'))
      return
    end
  end
  
def watch_save
    @meeting = Meeting.find(params[:id])
    @invitation = @meeting.invitation
    @invitee = current_member
    
    # Find or create a confirmation for this meeting & user.  
    @confirmation = @meeting.confirmations.find_by_member_id(@invitee.id) 
    if @confirmation.nil?
      @confirmation = @meeting.confirmations.build(:status_id => Status[:saved].id, :member_id => @invitee.id, :invitation_id => @meeting.invitation_id)
    end
        
    if @confirmation.new_record? 
      @invitation.confirmations << @confirmation
      @invitee.confirmations << @confirmation
      @confirmation.save
      msg = "The invitation has been added to the list of invitations you're watching."
    else
      msg = existent_confirmation_message(@confirmation.status)
    end
    # if request.xhr?
		meeting = params[:updateid]
    flash.now[:notice] = msg
		render :update do |page|
		  page.replace_html "search-mail"+params[:updateid], :partial => 'browse/save_meeting',:locals => {:meeting => meeting}
		  page.visual_effect :highlight, "search-mail"+params[:updateid]
		end

    # else
      # flash[:notice] = msg
      # redirect_to show_invite_url(:id => @invitation.id, :meeting_id => (@meeting.id rescue 'next'))
      # return
    # end
  end  

  def update
    @meeting = Meeting.find(params[:id])
    @invitation = @meeting.invitation
	
	invitee_status_keys = params.keys.select { |k| k =~ /status_for/ }
	invitee_status_keys.each do |key|
	  invitee_id = key.split('_')[-1]
	  app_or_rej = params[key].downcase.to_sym
	  confirmation = @meeting.confirmations.find_by_member_id(invitee_id)
	  new_status = (app_or_rej == :approve ? :confirmed : :rejected)
	  confirmation.status = Status[new_status]
	  
	  if confirmation.save
		url = show_invite_url( :id => @invitation.id, :meeting_id => @meeting.id, :member_id => confirmation.member.id, :key => confirmation.member.generate_security_token) 
		email = "deliver_#{app_or_rej == :approve ? 'acceptance_approved' : 'acceptance_declined'}".to_sym
		@message = message_handler(confirmation.meeting, [confirmation.member])
		InvitationNotify.send(email, confirmation, @message, url)
	  end
    end
	redirect_to show_invite_url(:id => @invitation.id, :meeting_id => @meeting.id)
	return
  end  
	

  private

  def get_confirmation
      @confirmation = Confirmation.find(params[:id]) rescue (redirect_to not_found_url and return false)
      @invitation  = @confirmation.invitation
      if @invitation.expired?
        flash[:notice] = "That action is not permitted. The invitation has expired."
        redirect_to show_invite_url(:id => @invitation.id) and return false
      end
  end

 	def get_invitation
	   params[:id] ||= params[:meeting_id]
	   @meeting   = Meeting.find( params[:id] ) rescue (redirect_to not_found_url and return false)
	   @invitation = @meeting.invitation
	   if @meeting.expired?
	      if request.xhr?
	         flash.now[:notice] = "That action is not permitted. The meeting has expired."   	
	         render
	      else
	         flash[:notice] = "That action is not permitted. The meeting has expired."
	         redirect_to show_invite_url(:id => @invitation.id) and return false
	      end
	      return false
	   end
	   return true
	end


  def accept_or_decline(acc_or_dec)
    @meeting = Meeting.find(params[:id])
    if current_member.invited_to(@invitation) || current_member.accepted(@meeting)  
      new_status = Status[(acc_or_dec == :accept ? :confirmed : :declined)]
      
      @confirmation = @meeting.confirmations.find_by_member_id(current_member.id) 
      if @confirmation.nil?
        @confirmation = @meeting.confirmations.build(:member_id => current_member.id, :invitation_id => @meeting.invitation_id)
      end

    if @confirmation.status_id != new_status.id
        @confirmation.status = new_status
        if  @confirmation.save
          url = show_invite_url( :id => @invitation.id,  :meeting_id => (@meeting.id rescue 'next'), :member_id => @invitation.inviter.id, :key => @invitation.inviter.generate_security_token) 
          message = message_handler(@meeting, [@invitation.inviter])
          email = "deliver_#{acc_or_dec == :accept ? 'approval_accepted' : 'approval_declined'}".to_sym
          InvitationNotify.send(email, @confirmation, message, url)
          msg = "Thanks!  We've notified #{@invitation.inviter.user_name} that you #{acc_or_dec == :accept ? "will" : "won't"} be attending."
          if( acc_or_dec == :decline && (reminder = Reminder.find_by_invitation_id_and_member_id(@meeting.invitation_id, current_member.id)) )
              reminder.destroy
          end
        end
      end

    	@member = current_member
    	@guest_responses = @invitation.guest_responses(@member, @meeting)

      if request.xhr?
        flash.now[:notice] = msg
      else
        flash[:notice] = msg
        redirect_to show_invite_url(:id => @invitation.id, :meeting_id => (@meeting.id rescue 'next')) 
        return
      end
    else
      # Imposter! 
      logger.error("Someone tried to accept an invite to which they were not invited.  User: #{current_member.user_name rescue 'nil'}.  Invite: #{@invitation.name rescue 'nil'}")
      redirect_to home_url
    end  
  end

  def approve_or_reject(app_or_rej, do_render = true) 
    if current_member.owner(@invitation)
      new_status = (app_or_rej == :approve ? :confirmed : :rejected)
      old_status = @confirmation.status.name
      @confirmation.status = Status[new_status]
      if @confirmation.save
        url = show_invite_url( :id => @invitation.id, :meeting_id => @confirmation.meeting.id, :member_id => @confirmation.member.id, :key => @confirmation.member.generate_security_token) 
        email = "deliver_#{app_or_rej == :approve ? 'acceptance_approved' : 'acceptance_declined'}".to_sym
        @message = message_handler(@confirmation.meeting, [@confirmation.member])
        InvitationNotify.send(email, @confirmation, @message, url)
        msg = "Thanks!  We've sent a notification email to #{@confirmation.member.user_name}."
      end
      if do_render
        if request.xhr?
          @viewer = current_member
          @to_update = []
          @to_update << (new_status.to_sym == :confirmed ? 'people_attending' : 'people_declined')
          @to_update << (old_status.to_sym == :accepted  ? 'people_requesting' : 'people_declined')
          @meeting = @confirmation.meeting
          @confirmations_remaining = Array(confirmations_needing_action())
          flash.now[:notice] = msg
        else
          flash[:notice] = msg
          redirect_to show_invite_url(:id => @invitation.id)
          return
        end
      end
    end  
  end
  
  def confirmations_needing_action()
    confirmations = @invitation.confirmations.find_by_meeting_id_and_status_id(@confirmation.meeting.id, Status[:accepted].id) 
  end

  def existent_confirmation_message(status)
    case status
    when Status[:saved]
      "You're already watching this invitation."
    when Status[:accepted]
      "You've already accepted this invitation."
    when Status[:approved]
      "You've been approved for this invitation. "
    when Status[:confirmed]
      "You're already confirmed for this invitation."
    when Status[:modified]
      "The invitation has been modified. You can re-confirm, or decline."
    when Status[:declined]
      "You've already declined this invitation."
    end
  end

end
