class MeetingInterest < ActiveRecord::Base

 belongs_to :member_profile
 validates_presence_of :interest

end
