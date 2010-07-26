# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  name                :string(255)   
#  address             :string(255)   
#  address2            :string(255)   
#  city                :string(255)   
#  state               :string(255)   
#  zip                 :string(255)   
#  latitude            :string(255)   
#  longitude           :string(255)   
#  airport_id          :integer(11)   
#  terminal_gate       :string(255)   
#  test_data           :boolean(1)    
#  zip_code_id         :integer(11)   
#  country             :string(255)   default(United States)
#  conference          :string(255)   
#  kind                :string(255)   
#  airport_type        :string(255)   
#  airport_non_us      :string(255)   
#
require 'geo_street_address'
class Address < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  include ChangedAttributes
  has_many :invitations
  belongs_to :airport
  belongs_to :zip_code   
  has_one :geocode

  def self.parse(address_string)
    address = self.new
    address.kind = 'regular'
    address_pieces = address_string.split(',')
    
    if address_pieces.length == 3
      address.name = address_pieces[0]
      address.address = address_pieces[0]
      address.city = address_pieces[1]
      address.state = address_pieces[2] 
      return address
    end
    
    gsa = GeoStreetAddress.parse_location(address_string)
    
    if gsa.blank?
      gsa = GeoStreetAddress.parse_location(address_string.gsub(/^[^,]+/, ''))
    end
    
    # Last-ditch regex...
    if gsa.blank?
      gsa = GeoStreetAddress.parse_named_place(address_string)
    end
    street_address = "#{gsa[:number]} #{gsa[:prefix]} #{gsa[:street]} #{gsa[:type]}"
    if street_address.blank?
      street_address = gsa[:place_name]
    end
    address.address = street_address
    [ :name, :city, :state, :zip ].each do |attribute|
      address.send("#{attribute.to_s}=", gsa[attribute]) unless gsa[attribute].blank?
    end      
    
    if address.name.blank?
      address.name = address_pieces[0] rescue ('None given')
    end
    
    return address
  end

  def validate
    unless kind == 'airport'
    
      if kind == "regular" and name.blank?
        errors.add(:name, " cannot be blank.") if name.blank?
      elsif kind == "conference" and conference.blank?
        errors.add(:conference, " cannot be blank.") if conference.blank?
      end
      #errors.add(:address, " cannot be blank.") if address.blank?
      errors.add(:city, " cannot be blank.") if city.blank?     
      errors.add(:state, " cannot be blank.") if(state.blank? and country == "United States")    
      errors.add(:country, " cannot be blank.") if country.blank?      
       
      unless((city.blank? and state.blank?) or (zip.blank?) or (country != "United States"))
        z1 = ZipCode.find_by_city_and_state_and_zip(city, state, zip)
        if z1.nil?
          errors.add(:zip, "and city/state did not match.")
        end
      end
    else
      if airport_type == 'airport_us'
        errors.add(:terminal_gate, " cannot be blank.") if terminal_gate.blank?
        errors.add(:airport_id, " Please choose an airport.") if airport_id.blank?
      elsif airport_type == 'airport_non_us'
        errors.add(:terminal_gate, " cannot be blank.") if terminal_gate.blank?        
        errors.add(:airport_non_us, " cannot be blank.") if airport_non_us.blank?
        errors.add(:country, " cannot be United States.") if country == 'United States'
      end
    end
  end   

  [:regular, :airport, :conference].each do |kind|
	   define_method("#{kind}?") do
		    self.kind == kind.to_s
		 end
	end

  def zip=(zc)
     zc = clean_text(zc)
     if zc
       zc.strip! 
       zc.gsub!(' ', '')
       # We do 5-digit zip codes only.
       write_attribute("zip", zc[0..5]) 
     else
       write_attribute("zip", '') 
     end
     update_zip_code
  end

  def city_alias_names
    self.zip_code.city_alias_names rescue []
  end

  def city
    if self.airport? and self.american?
      self.airport.city rescue ''
    else
      read_attribute('city')
    end
  end

  def state
    if self.airport? and self.american?
      self.airport.state rescue ''
    else
      read_attribute('state')
    end
  end
  
  def city=(ct)
     ct = clean_text(ct)
     write_attribute("city", ct)
     update_zip_code
  end
  
  def state=(st)
     st = clean_text(st)
     write_attribute("state", st)
     update_zip_code
  end

  def name=(n)
     n = '' if n == '(e.g., restaurant name)'
     write_attribute("name", clean_text(n))
  end
  
  def conference=(c)
     write_attribute("conference", clean_text(c))
  end
  
  def address=(a)
     write_attribute("address", clean_text(a))
  end

  def address2=(a)
     write_attribute("address2", clean_text(a))
  end

  def terminal_gate=(tg)
     write_attribute("terminal_gate", clean_text(tg))
  end

  def airport_non_us=(ap)
     write_attribute("airport_non_us", clean_text(ap))
  end

  def update_zip_code
     if(!zip.blank?)
        self.zip_code = ZipCode.find_by_zip(zip)
     elsif(!(state.blank? || city.blank?))
        self.zip_code = ZipCode.find_by_city_and_state(city, state)
     end
  end

  def clean_text(txt)
     return (txt.nil? ? nil : txt.strip_tags)
  end
  
  
    #This is really a hack.. Address should use single table inheritance.
  # That way the interface components would work better .
  def airport_country= name
      self.country = name if(self.country.blank?)
  end
  
  def airport_country
   self.country
  end
  

  def country_airport= name
      self.country = name if(self.country.blank?)
  end
  
  def country_airport
   self.country
  end
  
  def american?
    return (country == "United States" or ( !airport.nil? and airport.country == "United States"))
  end

  def display_name
    case self.kind
    when "regular"
    
      loc = self.name.dup
      loc = "Open" if loc.nil? or loc.blank?
      return loc
    when "conference"
      return self.conference.dup
    when "airport"
        airport_name()
    else
      return (self.name.dup rescue "")
    end
  end
  
  def sms_format
    result = display_name
    result << ", " unless result.blank?
    result << summary
    result
  end
       

  def airport_name
	   	case self.airport_type
    when 'airport_us'
      if self.airport.blank?
        return ""
      elsif self.airport.name.blank?
        return "#{self.airport.city} Airport"
      else
        return self.airport.name
      end
    when 'airport_non_us'
      return self.airport_non_us
    end
	end
  def link
    result = "http://maps.google.com/?q=loc:" 
    result << summary
  rescue
    return '#'
  end
  
  def summary 
    result = ''
    addr = (self.airport || self)
    address_line =  (addr.is_a?(Airport) ? addr.name : addr.address ) 
    result << address_line << ", " unless address_line.nil?
    ci_st_co = [addr.city, addr.state, addr.country].delete_if{ |a| a.blank? }
    city_state = ci_st_co.join(', ').sub(/, United States$/, '')
    result << city_state
    result
  end  

  def to_google_string     
	    result = ""
	   	addr = (self.airport || self)
	    address_line =  (addr.is_a?(Airport) ? addr.name : addr.address ) 
	    result << address_line << ", " unless address_line.blank?
	    ci_st_co = [addr.city, addr.state, addr.country].delete_if{ |a| a.blank? }
	    city_state = ci_st_co.join(', ').sub(/, United States$/, '')
	    result << city_state
	end
	
	def get_usable_geocode
	  return (geocode.usable? ? [geocode.latitude, geocode.longitude] : to_google_string)
	end

  def format
    result = ''    
    addr = (self.airport || self)
    result << "<a href=\"#{self.link}\" target=\"ttbmap\">#{self.display_name}</a> <br/>"
    case self.kind
    when "regular","conference"
      result << self.address << '<br/>' if !self.address.nil?
      
      result << self.address2 << '<br/>' unless self.address2.blank?
    when "airport"
      result << "Terminal/Gate: #{self.terminal_gate}" << '<br/>'
    end
    ci_st_co = [addr.city, addr.state, addr.country].delete_if{ |a| a.blank? }
    result << ci_st_co.join(', ').sub(/, United States$/, '')
    if result.blank?
      result = none_given("No address specified")
    end
    result
  end

  def time_zone
    city    = (self.airport ? self.airport.cities.first : self.city ).capitalize_each_word
    state   = (self.airport ? self.airport.state : self.state )
    tzinfo  = get_tzinfo(city, state, self.zip, self.country_code)
    # First try using the city to find the time zone
    # But compare offsets to avoid the time zone for 
    # Paris, France when the location is Paris, Texas
    if ( tz = TzinfoTimezone.new(city) ) and (tz.utc_offset == tzinfo.current_period.utc_offset)
logger.error("1 ADDRESS TIME ZONE: #{tz} (#{city},#{state},#{zip}, #{country_code})")
      return tz
    else
      if (tz = TzinfoTimezone.new(tzinfo.identifier) rescue nil)
        logger.error("2 ADDRESS TIME ZONE: #{tz} (#{city},#{state},#{zip}, #{country_code})")
        return tz
      # Try using the tzinfo object's offset        
      elsif (tz = TzinfoTimezone.new(tzinfo.current_period.utc_offset)rescue nil)
        logger.error("3 ADDRESS TIME ZONE: #{tz} (#{city},#{state},#{zip}, #{country_code})")
       
        return tz
      else
        logger.error("4 ADDRESS TIME ZONE: #{tz} (#{city},#{state},#{zip}, #{country_code})")
        
      # Give up!
        return nil
      end
    end
  end

  def get_tzinfo(city, state, zip, country_code)
    tz_country = TZInfo::Country.get( country_code )
    ## return the time zone for any country that has only one
    if tz_country.zones.collect { |z| z.current_period.zone_identifier }.uniq.size == 1
      return tz_country.zones.first
    ## Arizona is one of many special cases in the US.
    ## Currently it is the only one we are handling. If the 
    ## Zip code DB contained the correct daylight savings data
    ## This shouldn't be necessary.
    elsif tz_country.code == 'US' and state == 'AZ'
      return tz_country.zones.find {|z| z.identifier == 'America/Phoenix' }
    ## For the rest of the US use the ZipCode object to find the zone by the offset.
    elsif tz_country.code == 'US'
      zc = ZipCode.find_by_city_and_state(city, state) || ZipCode.find_by_zip(zip)  
      if zc
        return tz_country.zones.select { |tz| tz.current_period.utc_offset == zc.utc_offset  && TzinfoTimezone::MAPPING.values.include?(tz.name) }.sort.first
      end
    ## For the other 25+ countries, try using the city to find the TZInfo zone identifier
    else
      tz_country.zones.select {|z| z.identifier =~ /#{city.tr(' ','_')}/ }.first || nil 
      # tz_country.zones.first
      # Rather than returning nil we could return the first time zone for the country...
      # but that might look like a bug in the system, when it yields the wrong time zone
    end
  end

  def country_code
    COUNTRY_CODES[ ( self.airport ? self.airport.country : self.country ) ] rescue 'US' 
  end

  def self.country_code(country = 'United States')
    COUNTRY_CODES[ country ] rescue 'US'
  end

  USER_FACING_NAMES = { :name => 'Location', :airport_non_us => 'Airport' }
  
  AIRPORT_TYPES = {'In the US' => :airport_us, 'Outside the US' => :airport_non_us }
  
  COUNTRY_CODES = {
   "Latvia"=>"LV",
   "Heard Island & McDonald Islands"=>"HM",
   "Costa Rica"=>"CR",
   "Cote d'Ivoire"=>"CI",
   "United Arab Emirates"=>"AE",
   "Peru"=>"PE",
   "St Lucia"=>"LC",
   "Brunei"=>"BN",
   "Somalia"=>"SO",
   "Bolivia"=>"BO",
   "New Zealand"=>"NZ",
   "Palestine"=>"PS",
   "Northern Ireland"=>"IE",
   "Japan"=>"JP",
   "Oman"=>"OM",
   "Mozambique"=>"MZ",
   "Czech Republic"=>"CZ",
   "Myanmar (Burma)"=>"MM",
   "Trinidad and Tobago"=>"TT",
   "Korea (South)"=>"KR",
   "Kenya"=>"KE",
   "Greece"=>"GR",
   "Guadeloupe"=>"GP",
   "Dominican Republic"=>"DO",
   "Syria"=>"SY",
   "Armenia"=>"AM",
   "Heard and Mc Donald Islands"=>"HM",
   "Denmark"=>"DK",
   "Vanuatu"=>"VU",
   "Isle of Man"=>"IM",
   "Scotland"=>"GB",
   "Norway"=>"NO",
   "Reunion"=>"RE",
   "Malawi"=>"MW",
   "Sierra Leone"=>"SL",
   "Namibia"=>"NA",
   "Switzerland"=>"CH",
   "Qatar"=>"QA",
   "England"=>"GB",
   "Bhutan"=>"BT",
   "Turkey"=>"TR",
   "Haiti"=>"HT",
   "Tajikistan"=>"TJ",
   "Vietnam"=>"VN",
   "Lao People's Democratic Republic"=>"LA",
   "Iceland"=>"IS",
   "Turkmenistan"=>"TM",
   "Belgium"=>"BE",
   "France"=>"FR",
   "Serbia"=>"RS",
   "Venezuela"=>"VE",
   "Thailand"=>"TH",
   "Micronesia, Federated States of"=>"FM",
   "Congo"=>"CG",
   "St. Helena"=>"SH",
   "Equatorial Guinea"=>"GQ",
   "Tokelau"=>"TK",
   "San Marino"=>"SM",
   "Lebanon"=>"LB",
   "Sri Lanka"=>"LK",
   "Azerbaijan"=>"AZ",
   "Puerto Rico"=>"PR",
   "Korea (North)"=>"KP",
   "Solomon Islands"=>"SB",
   "French Guiana"=>"GF",
   "China"=>"CN",
   "Espana"=>"ES",
   "Seychelles"=>"SC",
   "Virgin Islands (UK)"=>"VG",
   "Marshall Islands"=>"MH",
   "Trinidad & Tobago"=>"TT",
   "Kazakhstan"=>"KZ",
   "Guam"=>"GU",
   "Burkina Faso"=>"BF",
   "Mexico"=>"MX",
   "Guinea-Bissau"=>"GW",
   "Ethiopia"=>"ET",
   "Vatican City State (Holy See)"=>"VA",
   "Pakistan"=>"PK",
   "Netherlands Antilles"=>"AN",
   "Libya"=>"LY",
   "Cape Verde"=>"CV",
   "Luxembourg"=>"LU",
   "Bahrain"=>"BH",
   "Panama"=>"PA",
   "Montenegro"=>"ME",
   "Georgia"=>"GE",
   "Nicaragua"=>"NI",
   "Sweden"=>"SE",
   "Martinique"=>"MQ",
   "United States"=>"US",
   "Spain"=>"ES",
   "Netherlands"=>"NL",
   "Russia"=>"RU",
   "Philippines"=>"PH",
   "Burundi"=>"BI",
   "Papua New Guinea"=>"PG",
   "US minor outlying islands"=>"UM",
   "Iran"=>"IR",
   "Congo, the Democratic Republic of the"=>"CD",
   "Serbia and Montenegro"=>"RS",
   "Antarctica"=>"AQ",
   "Uzbekistan"=>"UZ",
   "Bouvet Island"=>"BV",
   "Zambia"=>"ZM",
   "Finland"=>"FI",
   "Uganda"=>"UG",
   "South Korea"=>"KR",
   "Saint Lucia"=>"LC",
   "Pitcairn"=>"PN",
   "Mauritius"=>"MU",
   "Morocco"=>"MA",
   "Iraq"=>"IQ",
   "Lesotho"=>"LS",
   "Slovakia"=>"SK",
   "Argentina"=>"AR",
   "Jordan"=>"JO",
   "New Caledonia"=>"NC",
   "India"=>"IN",
   "United States Minor Outlying Islands"=>"UM",
   "Virgin Islands (U.S.)"=>"VI",
   "Chad"=>"TD",
   "South Georgia & the South Sandwich Islands"=>"GS",
   "Yemen"=>"YE",
   "Croatia"=>"HR",
   "Aruba"=>"AW",
   "Suriname"=>"SR",
   "Guyana"=>"GY",
   "Kuwait"=>"KW",
   "Wallis and Futuna Islands"=>"WF",
   "Belize"=>"BZ",
   "Andorra"=>"AD",
   "Nauru"=>"NR",
   "Estonia"=>"EE",
   "Tanzania"=>"TZ",
   "Central African Rep."=>"CF",
   "Macedonia"=>"MK",
   "Tunisia"=>"TN",
   "Guinea"=>"GN",
   "Mayotte"=>"YT",
   "Central African Republic"=>"CF",
   "Hungary"=>"HU",
   "Christmas Island"=>"CX",
   "Cocos (Keeling) Islands"=>"CC",
   "Nigeria"=>"NG",
   "Jersey"=>"JE",
   "Barbados"=>"BB",
   "Austria"=>"AT",
   "Saint Kitts and Nevis"=>"KN",
   "Mauritania"=>"MR",
   "Swaziland"=>"SZ",
   "Moldova"=>"MD",
   "Viet Nam"=>"VN",
   "Bangladesh"=>"BD",
   "Albania"=>"AL",
   "Congo (Dem. Rep.)"=>"CD",
   "Fiji"=>"FJ",
   "St Pierre & Miquelon"=>"PM",
   "Slovenia"=>"SI",
   "St Helena"=>"SH",
   "Faroe Islands"=>"FO",
   "Kyrgyzstan"=>"KG",
   "Malta"=>"MT",
   "Colombia"=>"CO",
   "Britain (UK)"=>"GB",
   "Comoros"=>"KM",
   "French Polynesia"=>"PF",
   "South Africa"=>"ZA",
   "Liechtenstein"=>"LI",
   "Bosnia and Herzegowina"=>"BA",
   "Sao Tome & Principe"=>"ST",
   "Macau"=>"MO",
   "Faeroe Islands"=>"FO",
   "Germany"=>"DE",
   "Moldova, Republic of"=>"MD",
   "Mongolia"=>"MN",
   "Eritrea"=>"ER",
   "Gibraltar"=>"GI",
   "Saudi Arabia"=>"SA",
   "Portugal"=>"PT",
   "Nepal"=>"NP",
   "Singapore"=>"SG",
   "Virgin Islands (British)"=>"VG",
   "Bulgaria"=>"BG",
   "Hong Kong"=>"HK",
   "Indonesia"=>"ID",
   "Brunei Darussalam"=>"BN",
   "Great Britain"=>"GB",
   "Cyprus"=>"CY",
   "Aaland Islands"=>"AX",
   "Korea, Republic of"=>"KP",
   "South Georgia and the South Sandwich Islands" => "GS",
   "St Kitts & Nevis"=>"KN",
   "Cayman Islands"=>"KY",
   "Samoa (Independent)"=>"WS",
   "Ukraine"=>"UA",
   "Bermuda"=>"BM",
   "St. Pierre and Miquelon"=>"PM",
   "Congo (Rep.)"=>"CG",
   "Bahamas"=>"BS",
   "Liberia"=>"LR",
   "Grenada"=>"GD",
   "St Vincent"=>"VC",
   "Botswana"=>"BW",
   "Cuba"=>"CU",
   "Rwanda"=>"RW",
   "Wallis & Futuna"=>"WF",
   "Wales"=>"GB",
   "Saint Vincent and the Grenadines"=>"VC",
   "Togo"=>"TG",
   "Sudan"=>"SD",
   "Anguilla"=>"AI",
   "Paraguay"=>"PY",
   "Virgin Islands (US)"=>"VI",
   "Antigua And Barbuda"=>"AG",
   "Lithuania"=>"LT",
   "British Indian Ocean Territory"=>"IO",
   "United Kingdom"=>"GB",
   "Samoa (western)"=>"WS",
   "Afghanistan"=>"AF",
   "Niger"=>"NE",
   "Mali"=>"ML",
   "Tonga"=>"TO",
   "Montserrat"=>"MS",
   "Myanmar"=>"MM",
   "Poland"=>"PL",
   "Northern Mariana Islands"=>"MP",
   "Turks and Caicos Islands"=>"TC",
   "Burma"=>"MM",
   "Dominica"=>"DM",
   "Taiwan"=>"TW",
   "Niue"=>"NU",
   "Romania"=>"RO",
   "Maldives"=>"MV",
   "Monaco"=>"MC",
   "Western Sahara"=>"EH",
   "Zimbabwe"=>"ZW",
   "American Samoa"=>"AS",
   "Sao Tome and Principe"=>"ST",
   "Ireland"=>"IE",
   "Micronesia"=>"FM",
   "Cambodia"=>"KH",
   "Turks & Caicos Is"=>"TC",
   "Trinidad"=>"TT",
   "Tuvalu"=>"TV",
   "Cook Islands"=>"CK",
   "Benin"=>"BJ",
   "Gabon"=>"GA",
   "Ghana"=>"GH",
   "Kiribati"=>"KI",
   "French Southern & Antarctic Lands"=>"TF",
   "Djibouti"=>"DJ",
   "Cameroon"=>"CM",
   "Guatemala"=>"GT",
   "El Salvador"=>"SV",
   "Greenland"=>"GL",
   "Guernsey"=>"GG",
   "Malaysia"=>"MY",
   "Madagascar"=>"MG",
   "Vatican City"=>"VA",
   "Palau"=>"PW",
   "Svalbard and Jan Mayen Islands"=>"SJ",
   "Egypt"=>"EG",
   "Norfolk Island"=>"NF",
   "Gambia"=>"GM",
   "Chile"=>"CL",
   "Senegal"=>"SN",
   "Laos"=>"LA",
   "Australia"=>"AU",
   "Canada"=>"CA",
   "Brazil"=>"BR",
   "Italy"=>"IT",
   "Bosnia & Herzegovina"=>"BA",
   "Falkland Islands"=>"FK",
   "Ecuador"=>"EC",
   "Uruguay"=>"UY",
   "Svalbard & Jan Mayen"=>"SJ",
   "Honduras"=>"HN",
   "Jamaica"=>"JM",
   "French Southern Territories"=>"TF",
   "East Timor"=>"TL",
   "Algeria"=>"DZ",
   "Belarus"=>"BY",
   "Israel"=>"IL",
   "Angola"=>"AO",
   "Samoa (American)"=>"AS",
   "Antigua & Barbuda"=>"AG"}

end
