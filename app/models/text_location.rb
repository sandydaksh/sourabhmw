class TextLocation
  CITY_STATE          = /\s*((\w+\s*){1,}),\s*((\w+\s*){1,})/ 
  CITY_STATE_COUNTRY  = /\s*((\w+\s*){1,}),\s*((\w+\s*){1,}),\s*((\w+\s*){1,})/ 
  ZIP_CODE            = /.*(\d{5}).*/
  CI = 1
  ST = 3
  CO = 5
  

  attr_accessor :city, :state, :country, :zip, :parsed
  def initialize(some_text)
    @original_text = some_text.strip
    parse
  end
  private 

  def parse
    if @original_text.match(ZIP_CODE)
      @zip = $1
      zc = ZipCode.find_by_zip(@zip)
      self.zip_code_obj = zc unless zc.nil?
      @parsed = true
      return
    elsif @original_text.match(CITY_STATE_COUNTRY)
      # Check to see if this is in the U.S.
      @country = Country::is_country_name?($~[CO])
      @city = $~[CI].capitalize_each_word
      @state = State::abbreviate($~[ST])
      # If it is, look up the zip code.
      if @country == "United States" 
        zc = ZipCode.find_by_city_and_state(@city, @state)
        self.zip_code_obj = zc unless zc.nil?
      end
      @parsed = true
    elsif @original_text.match(CITY_STATE)
      @city = $~[CI].capitalize_each_word
      # Check to see if this is a US state
      @state = State::abbreviate($~[ST])
      if @state.blank?
        # Check to see if it is maybe a city, country instead
        @country = Country::is_country_name?($~[ST])
      else
        zc = ZipCode.find_by_city_and_state(@city, @state)
        self.zip_code_obj = zc unless zc.nil?
      end
      @parsed = true
    else
      @parsed = false
    end
  end

  def parsed?
    return @parsed
  end

  def zip_code_obj=(zc)
    @city = zc.city.capitalize_each_word
    @state = zc.state
    @country = "United States"
    @zip = zc.zip
  end



end
