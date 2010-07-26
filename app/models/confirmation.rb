# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  invitation_id       :integer(11)   
#  member_id           :integer(11)   
#  state               :string(255)   
#  countered_invitation:integer(11)   
#  status_id           :integer(11)   
#  invited_as          :string(255)   
#


class Confirmation < ActiveRecord::Base
  belongs_to  :member,
              :class_name => 'Member',
              :foreign_key => 'member_id'
  belongs_to  :invitee,
              :class_name => 'Member',
              :foreign_key => 'member_id'
  belongs_to  :invitation,
              :class_name => 'Invitation',
              :foreign_key => 'invitation_id'
  
  belongs_to :meeting
  
  attr_accessor :status   
	attr_accessor :previous_status, :sent_notifications

  #  This is hear because we want to simply return false on the save if there is a duplicate record.
  # Helps stop multiple saves.
  def save(validate = true)
   begin
    super 
   rescue Exception => e 
    raise e unless e.message.match(/duplicate/i)
    errors.add(:base, "Duplicate confirmation")
    return false
   end
  end
  def status
    Status.find(self.status_id)
  end
  
  def status=(value)
    self.status_id = value.id
  end
  
  def rejected?
    return (self.status == Status[:rejected])
  end

  def declined?
    return (self.status == Status[:declined])
  end 

  def attending?
	   return (self.status == Status[:confirmed])
	end 
        
  def approved?
    return( self.status == Status[:approved])
  end
	
	def wants_to_attend?
		 return (self.status == Status[:accepted])
  end 
	
	def not_attending?
		 Status::NOT_ATTENDING.include?(self.status) 
 end
 
	def before_create
		 self.initially_invited = (self.status == Status[:approved] )     
		 return true
	end   
	
	def after_initialize
		 self.previous_status = self.new_record? ? 0 : self.status_id  rescue nil
	end  
	def status_changed?
		 self.status_id.to_s != previous_status.to_s
	end   
	
	

  protected
  
  # validates_uniqueness_of :member_id, :scope => :invitation_id
  
  def validate
    unless self.invitation.nil? or self.member.nil?
      if self.invitation.inviter == self.member
        errors.add(:member, "cannot accept their own invitations.")   
        return false
      end
    end
  end
end
