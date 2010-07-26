class ReminderMailer < ActionMailer::Base

  include MailerMethods  
  helper :invitation_notify

  def reminder(reminder, url)
    setup_email( get_emails(reminder.member) ) 
    @subject    = "Reminder for: #{reminder.invitation.name}"
    @body['invitation'] = reminder.invitation
    @body['reminder'] = reminder
    @body['member'] = reminder.member
    @body['url'] = url
  end

end
