class TextMessageNotifier < ActiveSms::Base
  include ActionView::Helpers::TextHelper

  MAX_LENGTH = 160

  def meeting_reminder(meeting, reminder)
    default_text_length = 82
    truncate_length = MAX_LENGTH - default_text_length
    @recipients = reminder.member.full_cell_phone_number
    @from       = 'travtab@meetingwave.com'
    @body       = "The meeting \"#{truncate(meeting.name, truncate_length)}\" will start at "
    @body       << "#{meeting.start_time_local.strftime('%I:%M%p on %a, %b %d').gsub(/^0/, ' ')}. "
    @body       << " Sent by MeetingWave.com."
    @options    = {}
  end

  def approval(invitation, recipients)
    
    @recipients = recipients.collect do |r| 
       (r.receives_sms_invites ? r.full_cell_phone_number : nil)
    end

	# Should delete blank numbers from recipient list here (not just nils)
    
    @recipients = @recipients.flatten.join(',')
    @from       = 'travtab@meetingwave.com'

    @body       = "#{truncate(invitation.inviter.user_name, 10)} invited you to: #{truncate(invitation.name, 20)}\n"
	remaining = MAX_LENGTH - (@body.size + 1)
    
    end_str    = "RSVP at MeetingWave.com"
	remaining -= end_str.size

    when_str   = "WHEN: #{invitation.start_time_local.strftime('%b %d@%I:%M%p')}\n"
	remaining -= when_str.size

	remaining -= "WHERE: .\n".size
    where_str  = "WHERE: #{truncate(invitation.address.sms_format, remaining)}.\n"

	@body << when_str << where_str << end_str

    @options    = {}
    logger.error("Delivering approval SMS to: #{@recipients}.  Length: #{@body.size}")
  end
end