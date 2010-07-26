class AccountEmail < ActiveRecord::Base
  
  belongs_to :member
  
  validates_presence_of :email,:message => "Please enter a valid email address."
  
  #~ def validate_on_create
    #~ eid = current_member.email.split('@')
    #~ univ = University.find(:first,:conditions => ["name = ?",@univ_account]).email_domains.map{|x| x.domain }
    #~ if univ.include?(eid[1])
      #~ errors.add_to_base("Please enter a valid email address.")
    #~ end
  #~ end
  
 def self.random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end
  
end
