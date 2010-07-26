class ContactObserver < ActiveRecord::Observer
   observe NonMemberApproval, Confirmation
   def logger
      RAILS_DEFAULT_LOGGER
   end
   def self.logger
      RAILS_DEFAULT_LOGGER
   end

   def after_create(record)
     if(NonMemberApproval === record)
       record.invitation.inviter.add_contact(record.non_member)
     end
     add_for_confirmation(record) if(Confirmation === record)   
   end 
   
   def after_update(record)
      add_for_confirmation(record) if(Confirmation === record)   
   end
   
   def add_for_confirmation(confirmation)        
       if(confirmation.approved? || confirmation.attending?)
         confirmation.member.add_contact(confirmation.invitation.inviter)
         confirmation.invitation.inviter.add_contact(confirmation.member)
       end
   end

end
