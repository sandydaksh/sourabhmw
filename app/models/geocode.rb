class Geocode < ActiveRecord::Base
	  belongs_to :address    
	
	  def usable?
		   !self.precision.nil?
		end
end
