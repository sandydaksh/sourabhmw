require 'mailer_methods'
class MessageMailer < ActionMailer::Base
  include MailerMethods
  helper :invitation_notify
  SUBJ_PREFIX = "MeetingWave.com:"
  
  
  def reply(message, recipient, url_invite, broadcast = false)

    url_invite = clean_url(url_invite)
    setup_email( get_emails(recipient) )
    # Email header info
    @subject = "#{SUBJ_PREFIX} #{message.meeting.invitation.name}" 
    # Email body substitutions
    @body['message']          = message.body rescue nil
    @body["author"]           = "#{message.author.user_name}"
    @body["recipient"]        = "#{recipient.user_name}"
    @body["invitation_name"]  = "#{message.meeting.invitation.name}"
    @body["broadcast"]        = broadcast
    @body["url_invite"]       = url_invite
  end

  def new(message, recipient, url_reply, url_invite)
    url_reply = clean_url(url_reply)
    url_invite = clean_url(url_invite)
    setup_email( get_emails(recipient) )
    # Email header info
    @subject += message.subject rescue "New message regarding: #{message.invitation.name}"
    # Email body substitutions
    @body['message']          = message.body rescue nil
    @body["author"]           = "#{message.author.user_name}"
    @body["recipient"]        = "#{recipient.user_name}"
    @body["invitation_name"]  = "#{message.invitation.name}"
    @body["url_reply"]        = url_reply
    @body["url_invite"]       = url_invite
  end
  



end