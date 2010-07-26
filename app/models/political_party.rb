# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#

class PoliticalParty < ActiveRecord::Base
  has_many :member_profiles
  NOT_TELLING = PoliticalParty.find_by_name("I'd rather not say.")

  OPTS = PoliticalParty.find(:all).collect { |p| [p.name, p.id] }
end
