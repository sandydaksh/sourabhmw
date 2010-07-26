# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  invitation_id       :integer(11)   
#  email               :string(255)   
#  created_at          :datetime      
#  security_token      :string(255)   
#

class NonMember < ActiveRecord::Base

  has_and_belongs_to_many  :messages,
                           :join_table => 'messages_non_members'

  # has_and_belongs_to_many :invitations, :foreign_key => 'non_member_guest_id'
     
     
     has_many :non_member_approvals, :dependent => :destroy
     has_many :invited_to_invitations, :through => :non_member_approvals, :source => :invitation
     
     
  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_uniqueness_of :email

  def generate_security_token
    if security_token.blank?
      self.update_attribute(:security_token, Digest::SHA1.hexdigest("#{Time.now}-saltydog-#{rand.to_s}")[0..39])
    end
    self.security_token
  end
  
  def user_name
    begin
    name || email
    rescue
      email
    end
  end
  
  def fullname 
    email
  end

protected

  def validate
     m = Member.find_by_email(email)
     unless m.nil?
       errors.add(:email, "The email address: #{email} belongs to an existing member.")
     end
  end
end
