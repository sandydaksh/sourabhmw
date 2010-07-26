class AddressObserver < ActiveRecord::Observer
   observe Address
   def logger
	   RAILS_DEFAULT_LOGGER
	end     
	 
	def after_update(address) 
		   address.invitations.reload
		   meetings = address.invitations.map(&:future_meetings).flatten   
		   # Let see I think we just need to resave the meetings so that they get updated
		
		   Meeting.transaction do 
			   meetings.each do | meeting|
				    meeting.save!
				 end
			end
	end
end