class InvitationObserver < ActiveRecord::Observer
   observe Invitation
   def logger
      RAILS_DEFAULT_LOGGER
   end

   MAX_NUM_FUTURE_MEETINGS = 12
   def self.logger
      RAILS_DEFAULT_LOGGER
   end

   def after_update(invitation)
      return if(!invitation.posted? || invitation.deactivated?)
      invitation.meetings.reload

      meetings = invitation.future_meetings
      # Let see I think we just need to resave the meetings so that they get updated
      if(meetings.empty?)
         after_create(invitation)
      elsif(invitation.changed? )
         handle_changed(invitation)
      else # Re-index
         Meeting.transaction do
            meetings.each do | meeting|
               meeting.save!
            end
         end

      end
          invitation.meetings.reload
          #invitation.ferret_update  # Re-index the invitation

   end 
   

   def handle_changed(invitation)

      if( invitation.recurring? )
         # Okay here we need to find all future meetings and delete them if there is a change in the schedule.
         # Also note there are going to be other observers that update the meeting if something in the address or invite changed.
         # This could get tricky with testing since you only want to reschedule meetings in the future.
         meetings = invitation.future_meetings

         Meeting.transaction do
            meetings.map(&:save)
         end
         after_create(invitation)
      else
         meetings = invitation.meetings
         meeting = meetings.first
         if(meeting)

            meeting.start_time = invitation.start_time
            meeting.end_time = invitation.end_time
            meeting.save!
         else
            logger.debug(" No meeting found for #{invite_schedule.invitation.id} what is up with that? -dave")
            after_create(invite_schedule)
         end

      end
      
        invitation.meetings.reload
         # invitation.ferret_update  # Re-index the invitation
   end


   # After the creation of an invite we need to create a meeting for it.
   # In the case of recurring invites we will need to create multiple
   # Meetings.


   def after_create(invitation)
      return unless(invitation.posted?)
      
      if( invitation.recurring? )
         Meeting.create_future_meetings(invitation, :re_index => true)
      else    
	       
         meeting = invitation.meetings.first ||  Meeting.new(:invitation_id => invitation.id)
         meeting.start_time =invitation.start_time
         meeting.end_time = invitation.end_time
         meeting.time_zone = invitation.time_zone
         meeting.save!
      end
      
          invitation.meetings.reload
          #invitation.ferret_update  # Re-index the invitation
   end

end
