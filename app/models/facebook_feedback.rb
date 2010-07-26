class FacebookFeedback < ActionMailer::Base

  def feedback(facebook_user,subject,feedback)
    @subject    =  "FacebookFeedBack: #{subject} from #{facebook_user.name}(#{facebook_user.id} )"
    @body       =  feedback + "\nReply: http://www.new.facebook.com/inbox/?compose&id=#{facebook_user.id}"
    @recipients = 'contact@meetingwave.com'
    @from       =  'contact@meetingwave.com'
    headers    = {}
  end
end
