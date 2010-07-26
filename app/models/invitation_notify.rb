require 'mailer_methods'
class InvitationNotify < ActionMailer::Base
  include MailerMethods  
  helper :invitation_notify
  SUBJ_PREFIX = "MeetingWave.com:"

  #self.view_paths = ActionView::PathSet.new()
 
  # Some hacks for Rails 2.3 
 
  #layout false
  # Notification to Inviter when an open invitation is accepted 
  # and they must approve or decline the potential invitee
  def acceptor(confirmation)
    setup_email( get_emails(confirmation.member) )  
    setup_inviter_invitee(confirmation) 


    @subject = "Your Interest in Attending Proposed Meeting #{confirmation.invitation.name}"    #{@invitee_name} has accepted your invitation to: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}"
    # Email body substitutions
   # @body['message']      = message.body rescue nil
    @body["inviter_name"] = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"] = "#{confirmation.member.user_name}"
    @body["invitation"]   = confirmation.invitation
    #@body["url"]          = url
	#@body["profile_link"] = member_profile_url(:host => 'www.meetingwave.com', :id => confirmation.member.id)
    #@body['occurrence']    = occurrence_date(confirmation,'for')
  end
  
  # Notification to Inviter when an open invitation is accepted 
  # and they must approve or decline the potential invitee
  def acceptance(confirmation, message, url)
    setup_email( get_emails(confirmation.invitation.inviter) )  
    setup_inviter_invitee(confirmation) 
	  url = clean_url(url)

    # Email header info   

    @subject = "Please confirm your meeting: #{confirmation.invitation.name}"    #{@invitee_name} has accepted your invitation to: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}"
    # Email body substitutions
    @body['message']      = message.body rescue nil
    @body["inviter_name"] = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"] = "#{confirmation.member.user_name}"
    @body["invitation"]   = confirmation.invitation
    @body["url"]          = url
	@body["profile_link"] = member_profile_url(:host => 'www.meetingwave.com', :id => confirmation.member.id)
    @body['occurrence']    = occurrence_date(confirmation,'for')
  end

  # Notification to Invitee when they are approved and confirmed by inviter
  def acceptance_approved(confirmation, message, url)
    setup_email( get_emails(confirmation.member) ) 
    setup_inviter_invitee(confirmation) 
	  url = clean_url(url)


    # Email header info
    @subject = "Re: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}, #{@inviter_name} has reserved a spot for you. "
    # Email body substitutions
    @body['message']      = message.body rescue nil
    @body["inviter_name"] = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"] = "#{confirmation.member.user_name}"
    @body["invitation"]   = confirmation.invitation
    @body["url"]          = url
    @body['occurrence']    = occurrence_date(confirmation,'for')    
  end

  # Notification to Invitee when they are declined by inviter
  def acceptance_declined(confirmation, message, url)
    setup_email( get_emails(confirmation.member) )  
    setup_inviter_invitee(confirmation)  
    url = clean_url(url)


    # Email header info
    @subject = "Re: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}, #{@inviter_name} has declined your attendance."
    # Email body substitutions
    @body['message']      = message.body rescue nil
    @body["inviter_name"] = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"] = "#{confirmation.member.user_name}"
    @body["invitation"]   =  confirmation.invitation
    @body["url"]          = url
    @body['occurrence']    = occurrence_date(confirmation,'for')    
  end
  
  # Notification to Invitee when they are pre-approved for an invitation
  # and they must accept or decline the inviter
  def approval(invitation, member, message, url)
    setup_email( get_emails(member) )  
    setup_inviter_invitee(nil, invitation)   
	  url = clean_url(url)


    # Email header info
    @subject = "#{@inviter_name} has invited you to: #{invitation.name}"
    # Email body substitutions
    @body['message']       = message.body rescue nil
    @body["inviter_name"]  = "#{invitation.inviter.user_name}"
    @body["invitee_name"]  = "#{member.user_name}"
    @body["invitation"]    = invitation                                                        
    @body["url"]           = url
  end
  
  def forward(invitation, forwarder, recipient, message , url)
     # Email header info
    setup_email( get_emails(recipient) )  
    setup_inviter_invitee(nil, invitation)   
     url = clean_url(url)
    @subject = "#{forwarder.fullname} thought you might be interested in: #{invitation.name}"
    # Email body substitutions
    @body['message']       = message rescue nil
    @body["inviter_name"]  = "#{invitation.inviter.user_name}"
    @body["forwarder"]  = forwarder.fullname
    @body["invitee_name"]  = (NonMember === recipient) ? "" : "#{recipient.user_name}"
    @body["invitation"]    = invitation                                                        
    @body["url"]           = url
  end
  
  def invite_to_meetingwave(member,non_member, message)
      setup_email( get_emails([non_member]) )  
      @subject = "Note from #{member.fullname} regarding MeetingWave.com"
      @body['full_name'] = member.fullname
    # Email body substitutions
    @body['message']       = message 

  end
  

  # Notification to Inviter when their invitation is accepted by invitee
  def approval_accepted(confirmation, message, url)
    setup_email( get_emails(confirmation.invitation.inviter) )  
    setup_inviter_invitee(confirmation)    
    url = clean_url(url)


    # Email header info
    @subject = "#{@invitee_name} has accepted your invitation to: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}"
    # Email body substitutions
    @body['message']          = message.body rescue nil
    @body['confirmation']     = confirmation
    @body["inviter_name"]     = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"]     = "#{confirmation.member.user_name}"
    @body["invitation"]       = confirmation.invitation
    @body["url"]              = url
    @body['occurrence']    = occurrence_date(confirmation,'for')    
  end

  # Notification to Inviter when their approval is declined by invitee
  def approval_declined(confirmation, message, url)
    setup_email( get_emails(confirmation.invitation.inviter) )  
    setup_inviter_invitee(confirmation)   
	  url = clean_url(url)


    # Email header info
    @subject = "#{@invitee_name} has declined your invitation to: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}"
    # Email body substitutions
    @body['message']      = message.body rescue nil
    @body['confirmation'] = confirmation
    @body["inviter_name"] = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"] = "#{confirmation.member.user_name}"
    @body["invitation"]   = confirmation.invitation
    @body["url"]          = url
    @body['occurrence']    = occurrence_date(confirmation,'for')
  end

  # Notification to Invitee when a confirmed invitation is modified
  # and they must accept or decline the inviter. Almost same as pre_approval
  def change_note(invitation, member, changed_attributes, message, url)
    setup_email( get_emails(member) )
    setup_inviter_invitee(nil,invitation) 
    url = clean_url(url)

    # Email header info
    @subject = "UPDATED: #{invitation.name}"
    # Email body substitutions
    @body['message']          = message.body rescue nil
    @body["inviter_name"]     = "#{invitation.inviter.user_name}"
    @body["invitee_name"]     = "#{member.user_name}"
    @body["invitation"]       = invitation
    @body["changed_attributes"] = changed_attributes
    @body["url"]                = url
  end

  # Notification to Inviter when their modification is accepted by invitee
  def change_accepted(confirmation, url)
    setup_email( get_emails(confirmation.invitation.inviter) )  
    setup_inviter_invitee(confirmation)     
	  url = clean_url(url)


    # Email header info
    @subject = "#{@invitee_name} has accepted your changes to: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}"
    # Email body substitutions
    @body["inviter_name"] = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"] = "#{confirmation.member.user_name}"
    @body["invitation"]   = confirmation.invitation
    @body["url"]          = url
    @body['occurrence']    = occurrence_date(confirmation,'for')    
  end
 
  # Notification to Inviter when their modification is declined by invitee
  def change_declined(confirmation, url)
    setup_email( get_emails(confirmation.invitation.inviter) )  
    setup_inviter_invitee(confirmation)  
	  url = clean_url(url)


    # Email header info
    @subject = "#{@invitee_name} has declined your changes to: #{confirmation.invitation.name}#{occurrence_date(confirmation,'-')}"
    # Email body substitutions
    @body["inviter_name"] = "#{confirmation.invitation.inviter.user_name}"
    @body["invitee_name"] = "#{confirmation.member.user_name}"
    @body["invitation"]   = confirmation.invitation
    @body["url"]          = url
    @body['occurrence']    = occurrence_date(confirmation,'for')    
  end

  def invitee_removed(invitation, invitee, url)
    setup_email( get_emails(invitation.inviter) )  
    setup_inviter_invitee(nil,invitation)   
	  url = clean_url(url)

    # Email header info
    @subject = "#{@invitee_name} has decided not to attend:  #{invitation.name}" 
    # Email body substitutions
    @body["inviter_name"] = "#{invitation.inviter.user_name}"
    @body["invitee_name"] = "#{invitee.user_name}"
    @body["invitation"]   = invitation
    @body["url"]          = url
  end
  
  def admin_deleted(invitation)
    setup_email( get_emails(invitation.inviter) )   
    setup_inviter_invitee(nil,invitation)

    # Email header info
    @subject = "Your Invite has been removed:  #{invitation.name}"
    # Email body substitutions
    @body["inviter_name"] = "#{invitation.inviter.user_name}"
    @body["invitation"]   = invitation
  end

  def inviter_destroyed(invitation, people_to_notify)
	setup_email(get_emails(people_to_notify), :bcc => true)
    setup_inviter_invitee(nil,invitation)

    # Email header info
    @subject = "#{@inviter_name} has cancelled the meeting:  #{invitation.name}"
    # Email body substitutions
    @body["inviter_name"] = "#{invitation.inviter.user_name}"
    @body["invitation"]   = invitation
  end

  def non_member_approval(invitation, non_member, message, url)
    setup_email( get_emails(non_member), { :from => invitation.inviter.email } )   
    setup_inviter_invitee(nil,invitation)   
	  url = clean_url(url)


    # Email header info
    @subject = "#{@inviter_name} has invited you to: #{invitation.name}"
    # Email body substitutions
    @body['invitation']   = invitation
    @body['message']      = message.body rescue nil
    @body["inviter_name"] = "#{invitation.inviter.user_name}"
    @body["invitation"]   = invitation
    @body["url"]          = url
  end

  def occurrence_date(conf, prepend='')
    if conf.invitation.no_pref != 1
      out = " #{prepend} #{conf.meeting.start_time_local.strftime("%B %d, %Y")}"
      out.strip! if prepend.blank?
      return conf.invitation.recurring? ? out : ''
    else
      txt = " No Preference"
      return txt
    end
  end
  
  # Notification to Inviter when they post an invitation
  def inviter_notice(invitation, message, url)
    setup_email( get_emails(invitation.inviter) )   
    setup_inviter_invitee(nil,invitation)    
	  url = clean_url(url)


    # Email header info
    @subject = "Your invite, #{invitation.name}, has been posted."
    # Email body substitutions
    @body['message']       = message.body rescue nil
    @body["inviter_name"]  = "#{invitation.inviter.user_name}"
    @body["invitee_name"]  = "#{invitation.inviter.user_name}"
    @body["invitation"]    = invitation
    @body["url"]           = url
  end     
  
  
  # Notification to Inviter when they post an invitation
  def invite_report(saved_search)
   default_url_options[:host] = "www.meetingwave.com" 
   
    setup_email( get_emails(saved_search.member) )   
    @body['saved_search'] = saved_search
    # Email header info
   # @subject = "MeetingWave:  #{saved_search.name} Invites since #{saved_search.last_send_time.strftime("%A, %B %d, %Y")} "
    
    @subject = "Your Upcoming Meetings from MeetingWave.com"
    # Email body substitutions
    @body['invitations']       = saved_search.invitations_to_send[0..10]
    @body['recurring_invitations'] = saved_search.recurring_to_send[0..10]
   
  end     

  def setup_inviter_invitee(confirmation, invitation = nil)
	    invitation = confirmation.invitation unless invitation
	    if(confirmation)
		     @invitee_name = confirmation.member.user_name
		  end
		
		  if(invitation)
			   @inviter_name = invitation.inviter.user_name
		  end 
	end
  
    
end
