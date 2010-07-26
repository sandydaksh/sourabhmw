class GeoLocation
   GEOIP = GeoIP.new("#{RAILS_ROOT}/data/GeoIPCity.dat")
   INDICES = {:country_abbrev => 2, 
              :country => 4, 
              :state  =>  6,
              :city   =>  7,
              :zip    =>  8,
              :lat    =>  9,
              :lon    => 10}

   INDICES.each do |name, index|
      meth_name = name.to_s
      define_method(meth_name) { return @geoip_data[index] }
      define_method(meth_name + "=") { |val| @geoip_data[index] = val }
   end

   def initialize(ip_address)
      @geoip_data = GEOIP.city(ip_address)
   end

   def set_default_if_blank
     if self.city.blank? or self.state.blank?
        self.city = "New York"
        self.country = "United States"
        self.country_abbrev = "US"
        self.state = "NY"
        self.zip = "10013"
     end
   end   
    
   def time_zone   
	   if(@cache_tzinfo ) 
	   	return @cache_tzinfo  		   
		 end
	   @cache_tzinfo = nil
     tzinfo  = Address.get_tzinfo(self.city, self.state, self.zip, self.country_abbrev)
     # First try using the city to find the time zone
     # But compare offsets to avoid the time zone for 
     # Paris, France when the location is Paris, Texas
     if ( tz = TzinfoTimezone.new(self.city) ) and (tz.utc_offset == tzinfo.current_period.utc_offset)
       @cache_tzinfo =  tz
     else
       # Try using the tzinfo object's identifier 
       if (tz = TzinfoTimezone.new(tzinfo.identifier)rescue nil)
	       @cache_tzinfo =  tz
       # Try using the tzinfo object's offset        
       elsif (tz = TzinfoTimezone.new(tzinfo.current_period.utc_offset)rescue nil)
	       @cache_tzinfo =  tz
       else
       # Give up!
         @cache_tzinfo =  tz
       end
     end 
     return @cache_tzinfo
   end

end
