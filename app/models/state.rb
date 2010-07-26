class State
        
   STATES = {
         'ALABAMA'               => 'AL',
         'ALASKA'                => 'AK',
         'AMERICAN SAMOA'        => 'AS',
         'ARIZONA'               => 'AZ',
         'ARKANSAS'              => 'AR',
         'CALIFORNIA'            => 'CA',
         'COLORADO'              => 'CO',
         'CONNECTICUT'           => 'CT',
         'DELAWARE'              => 'DE',
         'DISTRICT OF COLUMBIA'  => 'DC',
         'FEDERATED STATES OF MICRONESIA' => 'FM',
         'FLORIDA'               => 'FL',
         'GEORGIA'               => 'GA',
         'GUAM'                  => 'GU',
         'HAWAII'                => 'HI',
         'IDAHO'                 => 'ID',
         'ILLINOIS'              => 'IL',
         'INDIANA'               => 'IN',
         'IOWA'                  => 'IA',
         'KANSAS'                => 'KS',
         'KENTUCKY'              => 'KY',
         'LOUISIANA'             => 'LA',
         'MAINE'                 => 'ME',
         'MARSHALL ISLANDS'      => 'MH',
         'MARYLAND'              => 'MD',
         'MASSACHUSETTS'         => 'MA',
         'MICHIGAN'              => 'MI',
         'MINNESOTA'             => 'MN',
         'MISSISSIPPI'           => 'MS',
         'MISSOURI'              => 'MO',
         'MONTANA'               => 'MT',
         'NEBRASKA'              => 'NE',
         'NEVADA'                => 'NV',
         'NEW HAMPSHIRE'         => 'NH',
         'NEW JERSEY'            => 'NJ',
         'NEW MEXICO'            => 'NM',
         'NEW YORK'              => 'NY',
         'NORTH CAROLINA'        => 'NC',
         'NORTH DAKOTA'          => 'ND',
         'NORTHERN MARIANA ISLANDS' => 'MP',
         'OHIO'                  => 'OH',
         'OKLAHOMA'              => 'OK',
         'OREGON'                => 'OR',
         'PALAU'                 => 'PW',
         'PENNSYLVANIA'          => 'PA',
         'PUERTO RICO'           => 'PR',
         'RHODE ISLAND'          => 'RI',
         'SOUTH CAROLINA'        => 'SC',
         'SOUTH DAKOTA'          => 'SD',
         'TENNESSEE'             => 'TN',
         'TEXAS'                 => 'TX',
         'UTAH'                  => 'UT',
         'VERMONT'               => 'VT',
         'VIRGIN ISLANDS'        => 'VI',
         'VIRGINIA'              => 'VA',
         'WASHINGTON'            => 'WA',
         'WEST VIRGINIA'         => 'WV',
         'WISCONSIN'             => 'WI',
         'WYOMING'               => 'WY'
   }

   ABBREVS = STATES.invert

   def self.abbreviate(state_name)
     return state_name.upcase if state_name.size == 2
     abbrev = (STATES[state_name.upcase] || '')
   end

   def self.unabbreviate(state_abbrev)
     return ABBREVS[state_abbrev]
   end
   
   class << self
     def keyify(name)
       return name.upcase.gsub(/\s*/, '')
     end

     def is_state_name?(name)
       return @@states_lookup[keyify(name)]
     end
     alias :get_state :is_state_name?
      
   end
    
    @@states_lookup =  { }
    STATES.each do |name, abbrev| 
      @@states_lookup[abbrev] = name
      @@states_lookup[self.keyify(name)] = name      
    end

end
