class SavedSearch < ActiveRecord::Base
 
 serialize :data
 validates_presence_of :data
 belongs_to :member

 def after_initialize
  self.last_send_time ||= (self.created_at)
 end
 
 def needs_to_be_sent?(how_far_back)
    return (self.last_send_time.nil?  || self.last_send_time < Time.now - how_far_back)      
 end
 
 def content_to_send?(constrain_by_created_time = true)
  unless(@meetings)
   search_filter = SearchFilter.new(self.data.merge(:start_date => self.last_send_time.utc))
   @invitations = Invitation.invite_return(search_filter)
   #~ @meetings = search_filter.full_text_search({:limit => 1000}, ar_options)
   #~ inv_hash = {}
   #~ @invitations = @meetings.map(&:invitation).select{|inv| 
             #~ if(inv_hash[inv.id] || inv.admin_rating == 1 )
               #~ false
             #~ else
               #~ inv_hash[inv.id] = true
               #~ true
             #~ end
           #~ }
  end
  
  return invitations_to_send.length > 0
 end
 
 def invitations_to_send
  return ( @invitations_to_send ||= @invitations.select{|i| i.created_at > self.last_send_time}  )[0..10]
 end
 
 def recurring_to_send
   (@invitations - @invitations_to_send)[0..10]
 end
 
 def mark_sent!
  self.last_send_time = Time.now.utc
  save!
 end
 
 def toggle_email!
  self.email = !self.email
  self.save!
 end
 
 def send_if_available(force = false)
  if( force || content_to_send?)      
   logger.debug("SavedSearch: Found stuff to send for #{self.id} ")
   SavedSearch.transaction do 
    InvitationNotify.deliver_invite_report( self )
    self.mark_sent!
    return true
   end
  end
  return false
 end
 
 def self.send_all
    limit = 10 
    offset = 0
    
    while( searches = SavedSearch.find(:all, :limit => limit, :offset => offset, :conditions => {:email => true}) ) do 
     offset += limit
     break if searches.blank?
     searches.each do |search|
       begin
         search.send_if_available
       rescue
        logger.error("SavedSearch: Failed to send #{search.id} #{search.name}")
       end
       end
     end
    end
 
 
end
