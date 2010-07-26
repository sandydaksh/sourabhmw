# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#

class MilitaryBranch < ActiveRecord::Base
  has_and_belongs_to_many :member_profiles, :join_table => 'member_profiles_military_branches'
end
