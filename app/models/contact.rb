class Contact < ActiveRecord::Base
  belongs_to :member
  belongs_to :contactable, :polymorphic => true 
  #belongs_to :non_member , :polymorphic => true
  
  def self.create_contactables_for_emails(email_addresses)
    
    
    
    members  = Member.find_all_by_email(email_addresses)
    # Any remaining emails that are not already members will be represented as NonMembers.
    non_member_emails = (email_addresses - members.collect(&:email)) unless email_addresses.blank?
    unless non_member_emails.blank?
      non_members = non_member_emails.collect do |e| 
        NonMember.find_or_create_by_email(e)
      end 
    end
    members ||= []
    non_members ||= []
    
    return ( members | non_members )
  end
end
