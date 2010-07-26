class FacebookEmailCommunication < FacebookCommunication
	 validates_presence_of(:recipients)
   
   # fb_user.create_session.send_email( [fb_user.uid], "Subject Testing Email from background #{time}", "Text version of the email", 
   # 								<<-EOL
   #    						   <p> Hey there from the command line I have somethign to say.</p>
   #    						   <a href="http://apps.facebook.com/travelerstabledev">Check out our new features on Facebook</a>"
   #    						EOL
   #   						       )     
   #      

   def push
	    facebook_session.send_email(self.recipients, self.subject, self.text_body, self.html_body )
	 end

   def data
      if(super.blank?)
         self.data = Hash.new
      end
      return super
   end   

   def validate
	    
	     errors.add(:data, "Subject cannot be blank. ") unless self.subject
	     errors.add(:data, "Body cannot be blank") unless self.html_body || self.text_body
	 end

   def text_body=(text_body)
	    data[:text_body] = text_body
	 end    
	
	 def text_body
		  data[:text_body]
	 end  
	
	 def html_body=(html_body)
	    data[:html_body] = html_body
	 end    

	 def html_body
		  data[:html_body]
	 end
	
	 def subject=(subject)
		  data[:subject]  = subject
	 end
	
	 def subject
		  data[:subject]
	 end
	
end