class ContactMailer < ActionMailer::Base
  
  def feedback(user_email, user_name, user_subject, user_feedback)
    @subject = "[MeetingWave User Feedback] #{ user_subject }" 
    @recipients = [ "#{user_name} <feedback@meetingwave.com>" ] 
    @from = user_email 
    @sent_on = Time.now 
    @body["user_email"]    = user_email
    @body["user_name"]     = user_name
    @body["user_subject"]  = user_subject
    @body["user_feedback"] = user_feedback
    headers = {} 
  end
  
  def feedback_received(user_email, user_name)
     @subject = 'Thanks for your feedback!' 
      @recipients = [ user_email ]
      @from = '"MeetingWave" <feedback@meetingwave.com>'
      @sent_on = Time.now 
      headers = {}
      @body["user_email"] = user_email
      @body["user_name"]  = user_name
  end

end
