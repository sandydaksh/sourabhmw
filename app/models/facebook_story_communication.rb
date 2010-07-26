class FacebookStoryCommunication < FacebookActionCommunication

   def push
      fb_user.publish_story(self.action)
   end 

   def comm_class
	     Facebooker::Feed::Story 
	 end

end
