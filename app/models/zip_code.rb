# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  zip                 :string(255)
#  city                :string(255)
#  state               :string(255)
#  area_code           :string(255)
#  city_alias_name     :string(255)
#  city_alias_abbr     :string(255)
#  city_type           :string(255)
#  county_name         :string(255)
#  state_fips          :string(255)
#  county_fips         :string(255)
#  time_zone           :string(255)
#  day_light_saving    :boolean(1)
#  latitude            :string(255)
#  longitude           :string(255)
#  elevation           :string(255)
#  pt                  :integer       not null
#

# Copyright (c) 2006  Doug Fales
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
# 2006) and is released under the M

class ZipCode < ActiveRecord::Base
   # See: http://www.codeproject.com/dotnet/Zip_code_radius_search.asp
   # Equatorial radius of the earth from WGS 84
   # in meters, semi major axis = a
   A = 6378137;
   # flattening = 1/298.257223563 = 0.0033528106647474805
   # first eccentricity squared = e = (2-flattening)*flattening
   E = 0.0066943799901413165;
   # Miles to Meters conversion factor (take inverse for opposite)
   MILES_TO_METERS = 1609.347;
   # Degrees to Radians converstion factor (take inverse for opposite)
   DEGREES_TO_RADIANS = Math::PI/180;

   has_many :addresses

   def find_objects_within_radius(radius_in_miles, &finder_block)
      radius = radius_in_miles*MILES_TO_METERS
      lat0 = self.latitude * DEGREES_TO_RADIANS
      lon0 = self.longitude * DEGREES_TO_RADIANS
      rm = calc_meridional_radius_of_curvature(lat0)
      rpv = calc_ro_cin_prime_vertical(lat0)

      #Find boundaries for curvilinear plane that encloses search ellipse
      max_lat = (radius/rm+lat0)/DEGREES_TO_RADIANS;
      max_lon = (radius/(rpv*Math::cos(lat0))+lon0)/DEGREES_TO_RADIANS;
      min_lat = (lat0-radius/rm)/DEGREES_TO_RADIANS;
      min_lon = (lon0-radius/(rpv*Math::cos(lat0)))/DEGREES_TO_RADIANS;

      # Get all zips within min/mix here
      #zip_codes = self.find(:all, :conditions => ["latitude > ? AND longitude > ? AND latitude < ? AND longitude < ? ", min_lat, min_lon, max_lat, max_lon])
      zip_codes = yield(min_lat, min_lon, max_lat, max_lon)

      # Now calc distances from centroid, and remove results that were returned
      # in the curvilinear plane, but are outside of the ellipsoid geodetic
      result = {}
      zip_codes.each do |zip|
         z_lat = zip.lat * DEGREES_TO_RADIANS
         z_lon = zip.lon * DEGREES_TO_RADIANS
         distance_to_centroid = calc_distance_lat_lon(rm, rpv, lat0, lon0, z_lat, z_lon)
         result[zip] = distance_to_centroid  unless(distance_to_centroid > radius)
      end
      zip_codes = result.sort { |a, b| a[1] <=> b[1] }.collect { |z| z[0] }
      zip_codes
   end


   def find_all_within_radius(radius_in_miles)
	       find_objects_within_radius(radius_in_miles) do |min_lat, min_lon, max_lat, max_lon|
		        ZipCode.find(:all, :conditions => ["latitude > ? AND longitude > ? AND latitude < ? AND longitude < ? ", min_lat, min_lon, max_lat, max_lon])
		     end
	 end

   def find_objects_within_radius_of_city_state(city, state, radius_in_miles, &finder_block)
      radius = radius_in_miles*MILES_TO_METERS

      local_zip_codes = ZipCode.find(:all, :conditions => ["city = ? and state = ?", city, state])
      local_zip_codes.delete_if{ |zc| zc.lat.zero? and zc.lon.zero? }
      latitudes = local_zip_codes.collect(&:lat)
      longitudes = local_zip_codes.collect(&:lon)

      lat0, lat1 = latitudes.min, latitudes.max
      lon0, lon1 = longitudes.min, longitudes.max

      lat0 *= DEGREES_TO_RADIANS
      lon0 *= DEGREES_TO_RADIANS
      lat1 *= DEGREES_TO_RADIANS
      lon1 *= DEGREES_TO_RADIANS

      rm = calc_meridional_radius_of_curvature(lat0)
      rpv = calc_ro_cin_prime_vertical(lat0)

      #Find boundaries for curvilinear plane that encloses search ellipse
      max_lat = (radius/rm+lat1)/DEGREES_TO_RADIANS;
      max_lon = (radius/(rpv*Math::cos(lat1))+lon1)/DEGREES_TO_RADIANS;
      min_lat = (lat0-radius/rm)/DEGREES_TO_RADIANS;
      min_lon = (lon0-radius/(rpv*Math::cos(lat0)))/DEGREES_TO_RADIANS;

      # Get all zips within min/mix here
      #zip_codes = self.find(:all, :conditions => ["latitude > ? AND longitude > ? AND latitude < ? AND longitude < ? ", min_lat, min_lon, max_lat, max_lon])
      zip_codes = yield(min_lat, min_lon, max_lat, max_lon)

      # Now calc distances from centroid, and remove results that were returned
      # in the curvilinear plane, but are outside of the ellipsoid geodetic
      result = {}
      zip_codes.each do |zip|
         z_lat = zip.lat * DEGREES_TO_RADIANS
         z_lon = zip.lon * DEGREES_TO_RADIANS
         distance_to_centroid = calc_distance_lat_lon(rm, rpv, lat0, lon0, z_lat, z_lon)
         result[zip] = distance_to_centroid  unless(distance_to_centroid > radius)
      end
      zip_codes = result.sort { |a, b| a[1] <=> b[1] }.collect { |z| z[0] }
      zip_codes
   end

   def calc_distance_lat_lon(rm, rpv, lat0, lon0, lat, lon)
      Math::sqrt(  (rm ** 2) * ((lat-lat0)**2) + (rpv ** 2) * (Math::cos(lat0)**2) * ((lon-lon0) ** 2) )
   end


   def calc_meridional_radius_of_curvature(lat0)
      A*(1-E)/((1 - E * ((Math::sin(lat0) ** 2))) ** 1.5)
   end

   def calc_ro_cin_prime_vertical(lat0)
      A / Math::sqrt( 1 - E * (Math::sin(lat0) ** 2))
   end

   def lat() read_attribute(:latitude).to_f; end
   def lon() read_attribute(:longitude).to_f; end
   def latitude() read_attribute(:latitude).to_f; end
   def longitude() read_attribute(:longitude).to_f; end
   def utc_offset() (self.time_zone.to_i * -3600); end
   def self.zip_to_offset
	    map = (@@zip_to_offset ||= Hash.new() )
	    map 
	 end
   def self.find_offset_for(zip,city,state)
      if( zip )
         zc = ( zip_to_offset[zip] ||= ZipCode.find_by_zip(zip)  )
      elsif city and state
         zc = ZipCode.find_by_city_and_state(city,state)
      end

      if zc and !zc.time_zone.blank?
         return -(zc.time_zone.to_i * 1.hour)
      else
         return nil
      end
   end

   def city_alias_names
     @other_zips = ZipCode.find(:all, :conditions => [ " zip = ? ", self.zip])
     @other_zips.collect(&:city_alias_name)
   end

   def all_invitations
     self.addresses.collect(&:invitations).flatten.compact
   end

   def all_invitations_with_same_city_state
     all_zips = ZipCode.find(:all, :conditions => [ "city = ? and state = ?", self.city, self.state])
     all_addresses = all_zips.collect(&:addresses).flatten.compact
     all_addresses.collect(&:invitations).flatten.compact
   end

   def self.create_with_attributes_and_point(attributes)
     sql = <<-SQL
        INSERT INTO `zip_codes` (`city`, `county_name`, `elevation`, `latitude`, `zip`, `area_code`, \
        `state_fips`, `pt`, `day_light_saving`, `city_alias_name`, `city_type`, \
        `longitude`, `time_zone`, `city_alias_abbr`, `county_fips`, `state`) \
        VALUES('#{attributes["city"]}', '#{attributes["county_name"]}', '#{attributes["elevation"]}', '#{attributes["latitude"]}', \
        '#{attributes["zip"]}', '#{attributes["area_code"]}', '#{attributes["state_fips"]}', \
        (GeomFromText('POINT(#{attributes['latitude']} #{attributes['longitude']})')), \
        #{attributes["day_light_saving"]}, '#{attributes["city_alias_name"]}', '#{attributes["city_type"]}', \
        '#{attributes["longitude"]}', '#{attributes["time_zone"]}', '#{attributes["city_alias_abbr"]}', \
        '#{attributes["county_fips"]}', '#{attributes["state"]}') 
     SQL
     ActiveRecord::Base.connection.execute(sql)
   end

   private
   def find_center(lats, lons)
      offset = (lats.max - lats.min)/2.0
      lat = lats.min + offset
      offset = (lons.max - lons.min)/2.0
      lon = lons.min + offset
      [lat, lon]
   end
end
