# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  code                :string(255)   
#  name                :string(255)   
#  state               :string(255)   
#  country             :string(255)   
#  cities              :string(255)   
#

class Airport < ActiveRecord::Base
  has_many :addresses
  serialize :cities
  AIRPORT_OPTIONS = Airport.find(:all).collect { |a| ["#{a.cities[0]}, #{a.state} - #{a.code}", a.id] }.sort
  def city
    self.cities.first rescue ''
  end
end
