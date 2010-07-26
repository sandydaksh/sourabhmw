class FacebookNotificationCommunication < FacebookCommunication
   validates_presence_of(:recipients)
   def body=(body)
      self.data = body
   end

   def body
      self.data
   end

   def push    
      facebook_session.send_notification(self.recipients, self.body )
   end
end  

                                                         