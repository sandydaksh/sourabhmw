
class Employer < ActiveRecord::Base

  has_many :jobs
  has_many :member_profiles, :through => :jobs

end