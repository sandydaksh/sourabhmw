class ConfirmationsController < ApplicationController
  before_filter :login_required
  before_filter :get_confirmation
     
  def accept_approve
    if member? and @viewer.owner(@confirmation.invitation)
      @confirmation.status = Status[:confirmed]
      if @confirmation.save
        @message = message_handler(@confirmation, [@confirmation.member])
        auth = build_query_string(:member_id => @confirmation.member.id, :key => @confirmation.member.generate_security_token )
        url = url_for(:controller => 'invitations', :action => 'show', :id => @confirmation.invitation.id ) + auth
        InvitationNotify.deliver_acceptance_approved(@confirmation, @message, url)
        flash[:notice] = 'A confirmation was sent to the invitee.'
      end
      redirect_back_or_default :controller => 'invitations', :action => 'invitees',:id => @confirmation.invitation.id
    end  
  end

  def accept_decline
    if member? and @viewer.owner(@confirmation.invitation)
      @confirmation.status = Status[:declined]
      if @confirmation.save
        @message = message_handler(@confirmation, [@confirmation.member])
        auth = build_query_string(:member_id => @confirmation.member.id, :key => @confirmation.member.generate_security_token )
        url = url_for(:controller => 'invitations', :action => 'show', :id => @confirmation.invitation.id ) + auth
        # url_reply = url_for(:controller => 'invitations', :action => 'show', :id => @invitation.id) + auth        
        InvitationNotify.deliver_acceptance_declined(@confirmation, @message, url) #, url_reply)
        flash[:notice] = 'A notification was sent.'
      end
      redirect_back_or_default :controller => 'invitations', :action => 'invitees', :id => @confirmation.invitation.id
    end  
  end
 
  def approve_accept
    @invitation = @confirmation.invitation
    if member? and @viewer.owner(@confirmation)
      @confirmation.status = Status[:confirmed]
      if  @confirmation.save
        @message = message_handler(@confirmation, [@invitation.inviter])
        auth = build_query_string( :member_id => @invitation.inviter.id, :key => @invitation.inviter.generate_security_token )
        url = url_for( :controller => 'invitations', :action => 'invitees', :id => @invitation.id) + auth
        InvitationNotify.deliver_approval_accepted( @confirmation, @message, url)
        flash[:notice] = 'A confirmation was sent to the inviter'
      end
      redirect_back_or_default :controller => 'invitations', :action => 'myinvitations'
    else
      flash[:notice] = "You are not authorized for that action."
      redirect_to ''
    end  
  end

  def approve_decline
    @invitation = @confirmation.invitation
    if member? and @viewer.owner(@confirmation)
      @confirmation.status = Status[:declined]
      if @confirmation.save
        @message = message_handler(@confirmation, [@invitation.inviter])
        auth = build_query_string( :member_id => @invitation.inviter.id, :key => @invitation.inviter.generate_security_token )
        url = url_for( :controller => 'invitations', :action => 'invitees', :id => @invitation.id) + auth
        InvitationNotify.deliver_approval_declined( @confirmation, @message, url)
        flash[:notice] = 'A notification that you declined the invitation was sent to the inviter'
      end
      redirect_back_or_default :controller => 'invitations', :action => 'myinvitations'
    else
      flash[:notice] = "You are not authorized for that action."
      redirect_to ''
    end  
  end

  def change_accept
    @invitation = @confirmation.invitation
    if member? and @viewer.owner(@confirmation)
      @confirmation.status = Status[:confirmed]
      if @confirmation.save
        auth = build_query_string( :member_id => @invitation.inviter.id, :key => @invitation.inviter.generate_security_token )
        url_invitees = url_for( :controller => 'invitations', :action => 'invitees', :id => @invitation.id) + auth
        url_invitation = url_for( :controller => 'invitations', :action => 'show', :id => @invitation.id) + auth
        InvitationNotify.deliver_change_accepted( @confirmation, url_invitees, url_invitation )
        flash[:notice] = 'A notification was sent to the inviter'
      end
      redirect_back_or_default :controller => 'invitations', :action => 'myinvitations'
    else
      flash[:notice] = "You are not authorized for that action."
      redirect_to ''
    end    
  end

  def change_decline 
    @invitation = @confirmation.invitation
    if member? and @viewer.owner(@confirmation)
      @confirmation.status = Status[:declined]
      if @confirmation.save
        auth = build_query_string( :member_id => @invitation.inviter.id, :key => @invitation.inviter.generate_security_token )
        url_invitees = url_for( :controller => 'invitations', :action => 'invitees', :id => @invitation.id) + auth
        url_invitation = url_for( :controller => 'invitations', :action => 'show', :id => @invitation.id) + auth
        InvitationNotify.deliver_change_accepted( @confirmation, url_invitees, url_invitation )
        flash[:notice] = 'A confirmation was sent to the inviter'
      end
      redirect_back_or_default :controller => 'invitations', :action => 'myinvitations'
    else
      flash[:notice] = "You are not authorized for that action."
      redirect_to ''
    end    
  end

  def remove
    @invitation = @confirmation.invitation
    if member? and @viewer.owner(@confirmation)
      unless @confirmation.status == Status[:saved]
        auth = build_query_string( :member_id => @invitation.inviter.id, :key => @invitation.inviter.generate_security_token )
        url = url_for( :controller => 'invitations', :action => 'invitees', :id => @invitation.id) + auth
        InvitationNotify.deliver_invitee_removed(@invitation, @confirmation.member, url)
      end
      @confirmation.destroy
      flash[:notice] = "You have removed <b> #{@invitation.name} </b> from your invitations."      
    else
      flash[:notice] = "You can't #{:action} an invitation which you haven't saved or accepted"
    end
    if @confirmation.member.confirmations.empty?
      flash[:notice] += "<br />You don't have any invitations. Save or accept an open invitation first."
      redirect_to ''
    else
      redirect_to :controller => 'invitations', :action => 'myinvitations'
    end
  end

protected
    
  def get_confirmation
    member? # Authenticate incoming requests from email notifications
    @id = email_url_params(params) # Get the correct object id from email notification URLs
    begin
      @confirmation = Confirmation.find(@id)
      unless @confirmation.invitation.active?
        flash[:notice] = "That action is not permitted. <b>#{@confirmation.invitation.name}</b> has expired."
        redirect_to :controller => 'invitations', :action => 'show', :id => @confirmation.invitation.id
      end
    rescue
      @section = 'sectionthree'
      @errmsg = "The invitation you were looking for was not found. You may have an incomplete URL, or the invitation may have been deleted by the inviter."
      render :action => 'error' and return false
    end
  end

  def error
    # Wrapper
  end
  
end
