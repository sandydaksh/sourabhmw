require 'invite_utilities'
class InviteEditorController < ApplicationController
  include InviteUtilities
  helper :post_invite
  layout  'new_edit'

  before_filter :login_required
  before_filter :invite_owner

  # This displays the invitation in one condensed form so that it can be edited all at once.
  def edit
    @invitation = Invitation.find(params[:id])
    @address = @invitation.address
    @address = Address.new(:kind => 'regular') if @address.nil?    
    @email_addresses = @invitation.invited_non_members.collect { |nm| nm.email }
    @member_ids = @invitation.invited_members.collect{ |m| m.id.to_s }
    @members =  @invitation.invited_members
    check_render_facebook()
    #~ render :layout => "new_edit"
  end

  def save
    @invitation = Invitation.find(params[:id])

    # Save the original attributes so we know what to update people about (did the date change? did the address change? etc.)
    @original_invite_attributes = @invitation.attributes.dup
    @original_address_attributes = @invitation.address.attributes.dup if !@invitation.address.nil?

    (@email_addresses, @member_ids) = params["who-auto-field"].split(",").partition{ |item|  item.to_s.include?("@") }
    # Update the list of invitees using the incoming list of checked members and email addresses
    update_invitees(@invitation, @member_ids, @email_addresses)
    @members = @invitation.invited_members

    # This is sort of ghetto: in order to preserve the errors on start_time/end_time, we have to
    # add them to the model after validation occurs in .save below.  Note that recurring invites cannot have their
    # schedule chagned via the editor at this point.
    time_date_errors = { }
    unless @invitation.recurring?
      @invitation.time_zone = params[:invitation][:time_zone]
	  if mobile_request?
		  invp = params[:invitation]
		  entered_start_time = "#{invp['start_time_local(2i)']}/#{invp['start_time_local(3i)']}/#{invp['start_time_local(1i)']} #{invp[:start_time_local][:hour]}:#{invp[:start_time_local][:minute]} #{invp[:start_time_local][:meridiem]}"
		  entered_end_time = "#{invp['end_time_local(2i)']}/#{invp['end_time_local(3i)']}/#{invp['end_time_local(1i)']} #{invp[:end_time_local][:hour]}:#{invp[:end_time_local][:minute]} #{invp[:end_time_local][:meridiem]}"
		  invp.delete_if {|key, val| (key =~ /start_time_local/) or (key =~ /end_time_local/)  }
	  else
		  entered_start_time = params[:invitation][:start_time_local]
		  entered_end_time = params[:invitation][:end_time_local]
	  end
      begin
        @invitation.start_time = Time.parse_with_timezone(entered_start_time, params[:invitation][:time_zone])
      rescue InvalidTimeStringException => e
        time_date_errors[:start_time] = Invitation::EMPTY_TIME_DATE_MESSAGE
      end

      begin
        @invitation.end_time = Time.parse_with_timezone(entered_end_time, params[:invitation][:time_zone])
      rescue InvalidTimeStringException => e
        time_date_errors[:end_time] = Invitation::EMPTY_TIME_DATE_MESSAGE unless time_date_errors[:start_time]
      end
    end
    [ :start_time_local, :end_time_local].map{ |pseudo_attribute| params[:invitation].delete(pseudo_attribute)  }
    fix_undisclosed_address_bug() if !@invitation.address.nil? # Hack because of some weird checkbox issue during rails 2.3 upgrade.  I can't figure it out.

    # Finally, update the invite and its address
    @invitation.attributes = params[:invitation]
    
    if (params[:invitation][:purpose_id].to_i == Purpose::OTHER.id.to_i)
      @invitation.purpose = Purpose.new(:name => params[:other_purpose], :category => 'other')
    end


	if params[:address][:kind] == "yelp"
		@invitation.address.attributes = params[:yaddress]
		# We get a country code from Google, not the country name
		@invitation.address.country = Country::COUNTRIES[params[:yaddress][:country]]
		@invitation.address.kind = "regular"
    else
		@invitation.address.attributes = params[:address] if !@invitation.address.nil?
	end


    # Let's see if it's valid
    valid = (@invitation.save && time_date_errors.empty? && @invitation.address.save) if !@invitation.address.nil?
    valid = (@invitation.save && time_date_errors.empty?) if @invitation.address.nil?

    if(valid)

      new_members = @invitation.invited_and_unnotified_members
      new_non_members = @invitation.invited_and_unnotified_non_members

      existing_members = (@invitation.invited_and_notified_members + @invitation.confirmed_invitees).uniq
      existing_non_members = @invitation.invited_and_notified_non_members

      invite(@invitation, new_members)
      invite_non_members(@invitation, new_non_members)

      flash[:notice] = "Your invitation has been successfully updated!  "

      @changed_invitation_attributes = get_all_changed_attributes(@invitation, @original_invite_attributes, @original_address_attributes) if !@invitation.nil?

      if ((@invitation.invited_members.size > 0 or @invitation.invited_non_members.size > 0) and !@changed_invitation_attributes.blank?)
        session[:changed_attributes] = @changed_invitation_attributes
        redirect_to  notify_after_edit_url(:id => @invitation.id)
      else
        redirect_to  show_invite_url(:id => @invitation.id)
      end
    else
      time_date_errors.each { |attribute, error| @invitation.errors.add(attribute, error)}
      flash[:notice] = "Some errors prevented your invite from being updated.  Please correct the errors in each box below and hit Save All again."
      @address = @invitation.address
      @member_ids = @invitation.invited_members.collect{ |m| m.id.to_s }
      @invitee_profile = (@invitation.invitee_profile || InviteeProfile.new) 
      if( context?(:social_network) ) 
        render :action => "edit_fbml", :layout => "editor_fbml"
      else
        render :action => 'edit'
      end
    end

  end



  def notify
    @invitation = Invitation.find(params[:id])
    @invitees = ( @invitation.confirmed_invitees + @invitation.all_invited_members )
    @invitees.uniq!

    return unless request.post?
    
    members = (params[:members].blank? ? [] : Member.find(params[:members]))
    non_members = (params[:non_members].blank? ? [] : NonMember.find(params[:non_members]) )

    logger.error("Sending to members: #{members.collect(&:user_name).join(", ")}")
    logger.error("Sending to non_members: #{non_members.collect(&:user_name).join(", ")}")
    send_updates(@invitation, non_members + members, session[:changed_attributes]) 
    session[:changed_attributes] = nil
    flash[:notice] = "Notifications have been re-sent to your invitees to let them know of these changes."
    redirect_to  show_invite_url(:id => @invitation.id)
  end




  def copy
    @original = Invitation.find(params[:id])
    if params[:invitation].blank?
      @invitation = Invitation.copy(@original.attributes)
      @member_ids = []
      @members = []
      @email_addresses = []
      @address = @original.address
      @address = Address.new(:kind => 'regular') if @address.nil?
      check_render_facebook()
      #~ render :layout => "new_edit"
    else
      @invitation =  @viewer.invitations.build

      # First we take care of the address
	  if params[:address][:kind] == "saved"
      if !params[:address][:id].nil?
       logger.error("trying to find address: #{params[:address][:id]}")
       @address = Address.find(params[:address][:id])
      else
        add_hash = Hash.new
        add_hash = {:name => "Open",:city => current_member.member_profile.current_city, :country => current_member.member_profile.current_country,:state => current_member.member_profile.current_state}
       @address = Address.new(add_hash)
      end
	  else
		  params[:address] = fix_address_params(params)
		  @address = get_address(params[:address].dup) || Address.new(params[:address])
		  @address.save
	  end
	  @invitation.address = @address

      # Next is the time and date
      time_date_errors = { }
      @invitation.time_zone = params[:invitation][:time_zone]
      begin
        @invitation.start_time = Time.parse_with_timezone(params[:invitation][:start_time_local], params[:invitation][:time_zone])
      rescue InvalidTimeStringException => e
        time_date_errors[:start_time] = Invitation::EMPTY_TIME_DATE_MESSAGE
      end
      begin
        @invitation.end_time = Time.parse_with_timezone(params[:invitation][:end_time_local], params[:invitation][:time_zone])
      rescue InvalidTimeStringException => e
        time_date_errors[:end_time] = Invitation::EMPTY_TIME_DATE_MESSAGE unless time_date_errors[:start_time]
      end
      [:start_time_local, :end_time_local].map{ |pseudo_attribute| params[:invitation].delete(pseudo_attribute)  }

      # Now the params hash is safe to pass to our invitation
      @invitation.attributes = params[:invitation]
      @invitation.recurrence_frequency = nil if @invitation.recurrence_frequency == ''

      @invitation.mark_posted unless params[:draft]

      valid = (@invitation.save && time_date_errors.empty? && @invitation.address.save)

      unless valid
        time_date_errors.each { |attribute, error| @invitation.errors.add(attribute, error)}
        @invitation.mark_draft
        (@email_addresses, @member_ids) = params["who-auto-field"].split(",").partition{ |item|  item.to_s.include?("@") }
        @members = Member.find(@member_ids)
        logger.error("ERROR: The invitation with id #{@invitation.id} could not be saved during PostInvite#done because of these errors #{@invitation.errors.full_messages.join("\n")}")
        check_render_facebook()
        flash.now[:notice] = "Some errors prevented your invite from being posted.  Please correct the errors in each box below and hit Post Invite again."
        return
      end

      @meeting = @invitation.upcoming_meeting if @invitation.recurring?

      # Next deal with the invited members and non-members
      (@email_addresses, @member_ids) = params["who-auto-field"].split(",").partition{ |item|  item.to_s.include?("@") }
      update_invitees(@invitation, @member_ids, @email_addresses)
      @member_ids = @invitation.invited_members.collect{ |m| m.id.to_s }
      @members = @invitation.invited_members
      @email_addresses = @invitation.invited_non_members.collect(&:email)

      new_members = @invitation.invited_and_unnotified_members
      new_non_members = @invitation.invited_and_unnotified_non_members

      if @invitation.posted?
        invite(@invitation, new_members)
        invite_non_members(@invitation, new_non_members)
        notify_inviter(@invitation)
        flash[:notice] = "Your invitation has been posted!"
        redirect_to  show_invite_url(:id => @invitation.id)
      else
        @invitation.mark_draft
        @invitation.save
        flash[:notice] = "Your draft invitation has been saved!"
        redirect_to  drafts_url
      end
    end
  end

  def test
    render :layout => false
  end

  def get_all_changed_attributes(inv, original_invite_attributes, original_address_attributes)
    changed_invitation_attributes = inv.get_changed_attributes(original_invite_attributes)
    if !inv.address.nil?
      changed_address_attributes = inv.address.get_changed_attributes(original_address_attributes) 
      unless changed_address_attributes.blank?
        changed_invitation_attributes['address'] ||= {}
        changed_invitation_attributes['address']['old'] = Address.new(original_address_attributes).format
        changed_invitation_attributes['address']['new'] = inv.address.format
      end
    end
    changed_invitation_attributes
  end


  private


  def send_updates(invitation, people, changes)
    sent_to = []
    return if people.nil?

    # Hack!  I'd rather not do this.  I think the real solution will come in the form of better code in the changed_attributes module (and it wouldn't hurt to put our server on UTC)
    if changes.keys.include?('start_time')
      changes['start_time']['old'] = changes['start_time']['old'].utc.local_from_utc(invitation.time_zone)
      changes['start_time']['new'] = changes['start_time']['new'].utc.local_from_utc(invitation.time_zone)
    end

    if changes.keys.include?('end_time')
      changes['end_time']['old'] = changes['end_time']['old'].utc.local_from_utc(invitation.time_zone)
      changes['end_time']['new'] = changes['end_time']['new'].utc.local_from_utc(invitation.time_zone)
    end

    people.each do |person|
      begin
        conf = invitation.confirmations.find_by_member_id(person.id)
        next if (conf && (conf.rejected? || conf.declined?))
        response_params =  { :id => invitation.id,
          :member_id => person.id,
          :key => person.generate_security_token }
        url_invitation = show_invite_url(response_params)   # No meeting_id here so late responders see the next upcoming meeting
        message = prepare_message(invitation, conf, current_member, person)
        InvitationNotify.deliver_change_note(invitation, person, changes, message, url_invitation)
        sent_to << person.user_name
      rescue
        logger.error("PostInviteController#send_updates: Error sending updates to #{person.email}: #{$!}")
      end
    end
    sent_to
  end

  def invite_owner
    @invitation = Invitation.find(params[:id])
    if(current_member.owner(@invitation))
      return true
    else
      redirect_to home_url
      return false
    end

  end




end
