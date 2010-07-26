class MessagesController < ApplicationController
  helper :invitations
  helper :guest_response
  
  before_filter :login_required  
  layout 'invitations'
  
  def send_simple
    @meeting = Meeting.find(params[:message][:meeting_id])
    @person = Member.find(params[:message][:member_id])
    @invitation = @meeting.invitation
    @confirmation = @meeting.confirmations.find_by_member_id(@person.id)
    if @confirmation.nil?
      @confirmation = Confirmation.create(:member => @person, :invitation => @invitation, :meeting_id => @meeting.id, :status => Status[:new])
    end
    @message = Message.new(:body => params[:message][:body])
    @message.meeting = @meeting
    @message.invitation = @invitation
    return if @confirmation.nil?

    if @confirmation.member == current_member
      @recipient = @confirmation.invitation.inviter
    elsif @confirmation.invitation.inviter == current_member
      @recipient = @confirmation.member
    end

    @message.author = current_member
    @message.recipients << @recipient
    if @message.save
      auth = build_query_string( :member_id => @recipient.id, :key => @recipient.generate_security_token )
      url_invite = show_invite_url(:id => @message.invitation.id, :meeeting_id => (@meeting.id rescue 'next')) + auth
      MessageMailer.deliver_reply(@message, @recipient, url_invite)
    end    

  end
  
  def send_broadcast
     @meeting = Meeting.find(params[:meeting_id], :include => [{:confirmations => :member}, :invitation])
     @invitation = @meeting.invitation
     @recipients = []
     case params[:broadcast_recipients]
     when 'all'  # Everyone who has a confirmation record
       @recipients << @invitation.invited_members 
       @recipients << @invitation.invited_non_members
       @recipients << @meeting.people_requesting_invites
     when 'approved' # Only pre selected invitees
       @recipients << @meeting.confirmed_invitees
     when 'unapproved'
       @recipients << @meeting.not_attending_confirmations.reject{|conf| conf.status == Status[:declined]}.map(&:member)
     end
     
     @confirmations = []
     @recipients.flatten!
     @recipients.each do |rec|
       logger.error "!!!!!rec: #{rec} rec.class: #{rec.class} rec.methods: #{rec.methods.join(', ')}"
        conf = @meeting.confirmations.find_by_member_id(rec.id) 
        if conf.blank? and rec.is_a?(Member)
          conf = Confirmation.create(:meeting_id => @meeting.id, :invitation => @invitation, :member => rec, :status => Status['new'])
        end  
        @confirmations << conf unless conf.blank?
     end
     (@member_recipients, @non_member_recipients) = @recipients.partition { |m| m.is_a?(Member) }
     
     @message = Message.new(:body => params[:broadcast_message][:body], 
                            :invitation => @invitation,
                            :recipients => @member_recipients,
                            :non_members => @non_member_recipients,
                            :author => current_member, :meeting => @meeting)
      if @message.save
        @recipients.each do |rec|
          auth = build_query_string( :member_id => rec.id, :key => rec.generate_security_token )
          url_invite = show_invite_url(:id => @invitation.id, :meeting_id => (@meeting.id rescue 'next')) + auth
          MessageMailer.deliver_reply(@message, rec, url_invite,true)  
        end
      end
  end
  
  def send_from_invitee
    @meeting = Meeting.find(params[:message][:meeting_id])
    @message = Message.new(params[:message])
    @invitation = @message.meeting.invitation
    @recipient = @invitation.inviter
    @message.invitation = @invitation
    @message.recipients << @recipient
    @message.author = current_member
    if @message.save
      auth = build_query_string( :member_id => @recipient.id, :key => @recipient.generate_security_token )
      url_invite = show_invite_url(:id => @invitation.id, :meeting_id => (@meeting.id rescue 'next')) + auth
      MessageMailer.deliver_reply(@message, @recipient, url_invite)   
    else 
	    logger.error(" Couldn't save message from #{@message.author.fullname} to #{@recipient.fullname} #{@message.recipients.first.errors.full_messages.join("\n")}")
    end
  end


end
