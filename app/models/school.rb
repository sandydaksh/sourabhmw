# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#

class School < ActiveRecord::Base
  
  has_many :educations
  has_many :member_profiles, :through => :educations
    
end
