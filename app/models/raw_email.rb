class RawEmail < ActiveRecord::Base     
	 set_table_name :emails
	 SUBJECT_MATCH = /\sSubject:\s*(.*?)\s*Mime/ 
	 HTML_MATCH = /(<html>.*<\/html>)/m
	 def subject
		  @subject ||= self.raw_email.subject
	 end  
	
	 def html  
	    raw_email.body.match(HTML_MATCH)[1] rescue "<pre>#{raw_email.body}</pre>" 
	 end    
	
	 def failed?
		   self.last_send_attempt	 > 0
	 end     
	
	 def need_to_send?
		   self.deleted == false
	 end   
	
	 def failed_at
		   Time.at(self.last_send_attempt)
	 end
		
		
	
	 def raw_email   
		   return @raw_email if @raw_email
		   @raw_email  ||= TMail::Mail.parse(self.mail)
       @raw_email.base64_decode    
       @raw_email
		end     
		
end         
