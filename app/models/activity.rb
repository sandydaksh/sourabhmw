# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#

class Activity < ActiveRecord::Base;
  has_many :invitations
  ACTIVITY_OPTS = Activity.find(:all).collect { |a| [a.name, a.id] }
  OTHER = Activity.find_by_name('Other')
end
