# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  member_id           :integer(11)   
#  invitation_id       :integer(11)   
#  time                :datetime      
#

class Notification < ActiveRecord::Base
   belongs_to :invitation
   belongs_to :member


end
