class SearchFilter
   attr_accessor :activity_id
   attr_accessor :airport_id
   attr_accessor :client_tz_offset
   attr_accessor :location
   attr_accessor :purpose_id  
   attr_accessor :romance
   attr_accessor :city
   attr_accessor :state
   attr_accessor :country 
   attr_accessor :stars   # We call this "stars" because it is slightly different from the admin_rating--it is a zero to 5 scale, not a -1, 1-5 scale
   attr_accessor :terms  
   attr_accessor :description
   attr_accessor :start_date
   attr_accessor :end_date
   attr_accessor :start_time
   attr_accessor :end_time
   attr_accessor :zip
   attr_accessor :radius
   attr_accessor :category
   attr_accessor :query_string
   attr_accessor :filter_proc
   attr_accessor :sort_options
   attr_accessor :person
   attr_accessor :preference_flag
   attr_accessor :virtual_flag
   attr_accessor :no_pref
   

   include Runt

   def initialize(attributes={})   
      attributes = attributes.clone
      @romance = '0'
      attributes.reject! { |k,v| v == '' }
      @client_tz_offset = get_tz_offset(attributes)
      attributes.delete(:client_tz_offset)
      @start_date = get_date(attributes, :start_date)
      @end_date = get_date(attributes, :end_date)
      attributes.delete(:start_date)
      attributes.delete(:end_date)
	  self.radius = '25' unless attributes.include?(:radius)
      attributes.each do |attr_name, attr_val|
         unless attr_val.blank?
            self.send("#{attr_name}=",attr_val.to_s)  rescue nil
         end
      end
      clean_text_attributes
   end
   
    
   def build_query_string(options)
       @filter_proc = nil
       @sort_options = nil
       options[:page] ||= 1
       options[:limit] ||= PER_PAGE
       options[:offset] = options[:limit] * (options[:page].to_i - 1)  

       start_date = Time.now.utc unless start_date.is_a?(Time)  # THIS SEEMS LIKE  A BUG TO ME!!!  Should be self.start_date

       if (end_date and end_date < start_date)
           ed = self.end_date           
           self.end_date = self.start_date
           self.start_date = ed
       end
         

       search_string = ''
       search_string << 'draft_status: posted '
       search_string << '+private: false '
       search_string << ' name|description|city|city_alias_names|activity_name|address_name: "' + terms + '" '  unless terms.blank?
  	   search_string << ' person: "' + person + '" ' unless person.blank?
       search_string << " purpose_id: #{purpose_id} "   unless purpose_id.blank?
       search_string << " -purpose_id:19"               if romance.to_i.zero?
       search_string << " activity_id: #{activity_id} " unless activity_id.blank?
       search_string << " airport_id: #{airport_id} "   unless airport_id.blank?  
       search_string << " description: #{description} "   unless description.blank?
       search_string << " address_name: #{location} "   unless location.blank?
       search_string << " country: #{country} "         unless country.blank?
       search_string << " preference_flag: #{preference_flag}"  unless preference_flag.to_i.zero?
       #~ search_string << " virtual_flag: 1"  if virtual_flag.to_i.zero?
       search_string << " virtual_flag: #{virtual_flag}"  unless virtual_flag.to_i.zero?
       search_string << " stars: [#{stars}>"         unless stars.blank?
       search_string << " +category:#{category} "     unless category.blank?
       search_string << zip_code_conditions

       time_date_string, @filter_proc = time_date_conditions if preference_flag.to_i.zero? || preference_flag.blank?
       search_string << time_date_string if preference_flag.to_i.zero? || preference_flag.blank? 
       @sort_options = use_invitation() ? "next_occurrence_idx" : "start_time_idx" if preference_flag.to_i.zero? || preference_flag.blank?
       
       @query_string = search_string
       
       logger.info "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU"
       logger.info @query_string
       
   end
   
   def a_good_name
       best_name_in_order = [:person, :description, :location,  :city, :state, :country, :zip ]
       name = ""
       best_name_in_order.each do |try|
          name = self.send(try) || name
          break unless name.blank?
       end
       
       if( self.terms )
         name = self.terms + " " +  name 
       end
       return name
   end
   
   def use_invitation(options = {})
    @use_invitation  ||= options.delete(:use_invitation)
   end
   
     BROWSE_INCLUDES =  [ 
        { :invitation => [:address, {:inviter => { :member_profile => :picture}}] },
        {:confirmations => :member}        
        ]
        
   
    INVITATION_BROWSE_INCLUDES =  [ :address, :meetings, {:inviter => { :member_profile => :picture }}, {:confirmations => :member } ];
      
     DEFAULT_INCLUDES =  [ { :invitation => :address }, {:confirmations => :member} ]        
    # Pass in active record options that you want during the load.
		def full_text_search(options, ar_options ={})
                 klass = use_invitation(options) ? Invitation : Meeting
           ar_options[:include] ||= DEFAULT_INCLUDES
		   build_query_string(options)

		   options[:sort] = @sort_options unless @sort_options.nil?
		   options[:page] ||= 1
           logger.debug "SEARCH STRING: #{@query_string} OPTIONS: #{options.to_yaml}"

		   begin
		      results = klass.paginate_search(@query_string, options, ar_options)   
		   rescue
		      logger.error("Error while searching with search string: #{@query_string}")
		      logger.error("Error was: #{$!}.")
		      logger.error($!.backtrace.join("\n"))
		      return WillPaginate::Collection.new(0, 20, 0)  # This is wrong actually.  We need to return an empty paginator...  Might be somethign like this WillPaginate::Collection.new(page, per_page, total_hits) ?? 
		   end
                   results.each do |result|
                     result.extend(TTB::CoerceInvitation)
                     result.filtered_date = self.start_date
                   end
                   
                   
                   #~ real_results = results.sort_by{|inv| inv.start_time_local }
                   #~ real_results.extend(TTB::CoerceResults)
                   #~ real_results.real_results = results
		   return  results
		end


   def time_date_conditions
      result = []
      filter = nil
      
    
    start_key = "start_time_idx_2"
    end_key = "end_time_idx"
    Invitation::MAX_MEETINGS.times do |time|
        start_key = "start_time_idx" + ( ( time == 0) ? "" : "_#{time + 1}" )
        end_key = "end_time_idx" + ( ( time == 0) ? "" : "_#{time + 1}" )

    
      # We need to use a filter to get rid of recurring events for which there is no instance during the specified window.
      if start_time_idx and end_time_idx
        result << " (#{start_key}: >= #{start_time_idx} AND #{end_key}: <= #{end_time_idx}) "    
      elsif start_time_idx.blank? and end_time_idx
        result << " (#{end_key}: <= #{end_time_idx}) "    
      elsif end_time_idx.blank? and start_time_idx
        result << " (#{start_key}: >= #{start_time_idx}) "    
      else
        
      end
    end
      return "( #{result.join(" OR ") }) ", filter   
    end
    
   def time_date_conditions_new
      result = []
      filter = nil
      
    
    start_key = "start_time_idx_2"
    end_key = "end_time_idx"
    Invitation::MAX_MEETINGS.times do |time|
        start_key = "start_time_idx" + ( ( time == 0) ? "" : "_#{time + 1}" )
        end_key = "end_time_idx" + ( ( time == 0) ? "" : "_#{time + 1}" )

    
      # We need to use a filter to get rid of recurring events for which there is no instance during the specified window.
      if start_time_idx and end_time_idx
        result << " (#{start_key}: >= #{start_time_idx} AND #{end_key}: <= #{end_time_idx}) "    
      elsif start_time_idx.blank? and end_time_idx
        result << " (#{end_key}: <= #{end_time_idx}) "    
      elsif end_time_idx.blank? and start_time_idx
        result << " (#{start_key}: >= #{start_time_idx}) "    
      else
        
      end
    end
      return "( #{result.join(" OR ") } ) ", filter   
   end
    

   def zip_code_conditions

      if zip.blank? and city.blank? and state.blank?
       return ''
      end
      if(!zip.blank?)
         @zip_code = ZipCode.find_by_zip(zip)
      elsif(!(city.blank? or state.blank?))
         @zip_code = ZipCode.find_by_city_and_state(city, state)
      end

      zips_to_search_for = []
      range_conditions = ''
      if(@zip_code and radius.blank?)
         zips_to_search_for = [ @zip_code ]
      elsif (zip.blank? and !(city.blank? or state.blank?) and @zip_code)
        @zip_code.find_objects_within_radius_of_city_state(city, state, radius.to_i) do |min_lat, min_lon, max_lat, max_lon|
            p1, p2, p3, p4 = ["#{max_lat} #{max_lon}", "#{max_lat} #{min_lon}", "#{min_lat} #{min_lon}","#{min_lat} #{max_lon}"]

            my_min_lon = [min_lon.to_s, max_lon.to_s].min
            my_max_lon = [min_lon.to_s, max_lon.to_s].max
            range_conditions = " lat:[#{fescape(min_lat)} #{fescape(max_lat)}] lon:[#{fescape(my_min_lon)} #{fescape(my_max_lon)}]"
            zips_to_search_for = ZipCode.find_by_sql(%{SELECT * FROM zip_codes WHERE MBRContains(GeomFromText('Polygon((#{p1},#{p2},#{p3},#{p4},#{p1}))'), pt) limit 1;})
         end
      elsif @zip_code
         @zip_code.find_objects_within_radius(radius.to_i) do |min_lat, min_lon, max_lat, max_lon|
            p1, p2, p3, p4 = ["#{max_lat} #{max_lon}", "#{max_lat} #{min_lon}", "#{min_lat} #{min_lon}","#{min_lat} #{max_lon}"]

            my_min_lon = [min_lon.to_s, max_lon.to_s].min
            my_max_lon = [min_lon.to_s, max_lon.to_s].max
            range_conditions = " lat:[#{fescape(min_lat)} #{fescape(max_lat)}] lon:[#{fescape(my_min_lon)} #{fescape(my_max_lon)}]"
            zips_to_search_for = ZipCode.find_by_sql(%{SELECT * FROM zip_codes WHERE MBRContains(GeomFromText('Polygon((#{p1},#{p2},#{p3},#{p4},#{p1}))'), pt) limit 1;})
         end
      end


      # If we don't recognize this location, then we just do a fulltext search
      # on the zip, city, and state.
      if zips_to_search_for.size.zero?
         conditions = ''
         conditions << " +zip:#{zip}" unless zip.blank?
         conditions << " +city:#{city}" unless city.blank?
         conditions << " +state:#{State::unabbreviate(state)}" unless state.blank?
         return conditions
      else 
         return range_conditions
      end

   end

   def fescape(s)
      s.to_s.gsub("-", '\-')
   end

   #def start_time_idx()  return (self.start_date.strftime("%Y%m%d%H%M") rescue Time.now.strftime("%Y%m%d%H%M")); end
   def start_time_idx()  return (self.start_date.strftime("%Y%m%d%H%M") rescue nil); end
   def end_time_idx()    return (self.end_date.strftime("%Y%m%d%H%M") rescue nil); end

   def to_params(opts = { :include_query_string => false })
      params = {}
      self.instance_values.each do |k, v|
		  if(k == 'query_string' and !opts[:include_query_string])
			  next
          elsif(v and v.is_a?(Date) or v.is_a?(Time))
             params["search_filter[#{k}]"] = v.strftime("%Y%m%d")
          else
            params["search_filter[#{k}]"] = v unless v.blank?
          end
      end
      params
   end
   
   def to_hash
      params = {}
      self.instance_values.each do |k, v|
          if(v and v.is_a?(Date) or v.is_a?(Time))
             params[k] = v.strftime("%Y%m%d")
          else
            params[k] = v unless v.blank?
          end
      end
      params
   end
   
   def to_param_string
     to_params.collect do |k,v|
       "#{k}=#{v}"
     end.join("&")
     
   end
   
   def to_rss_params
      p = self.to_params
      p[:format] = 'rss'
      p
   end

   FQL_CHARS = %w{ : ( ) [ ] \{ \} ! + " ~ ^ - | < > = * ? \\ ; ' }
   def clean_text_attributes 
	    
      FQL_CHARS.each do |c|
         @zip.gsub!(c, ' ')      unless @zip.nil?
         @city.gsub!(c, ' ')     unless @city.nil?
         @state.gsub!(c, ' ')    unless @state.nil?
         next if c == "'"
         @terms.gsub!(c, ' ')    unless @terms.nil?
         @location.gsub!(c, ' ') unless @location.nil?
      end
      @terms.strip!     unless @terms.nil?
      @zip.strip!       unless @zip.nil?
      @city.strip!      unless @city.nil?
      @state.strip!     unless @state.nil?
      @location.strip!  unless @location.nil?
   end

   def category=(cat)
     cat = nil if(cat.to_sym == :all)
     @category = cat
   end

   def airport_id
     return (@airport_id.nil? ? @airport_id : @airport_id.to_i)
   end

   def purpose_id
     return (@purpose_id.nil? ? @purpose_id : @purpose_id.to_i)
   end

   def activity_id
     return (@activity_id.nil? ? @activity_id : @activity_id.to_i)
   end

   def logger
      ActiveRecord::Base.logger
   end

   def blank?
     attrs = self.methods.grep(/\w+\=$/) - [ "radius=", "client_tz_offset=", "romance=", "taguri=" ]
     result = true
     attrs.each do |a| 
       val = self.send(a[0...-1])
       result &= val.blank?
     end
     result
   end
   
   def self.get_for_terms(terms = '', opts = {})
    
    if terms =~ RE::CITY_STATE
      city, state = $1, $2
      q = terms.gsub(Regexp.new($~.to_s), '')
      puts "Here: #{city}, #{state}"
      search_filter_hash = {:terms => q, :city => city, :state =>  state, :radius => 25}
    elsif terms =~ RE::ZIP_CODE
      search_filter_hash = {:terms => '', :zip => $1, :radius => 25}
    elsif (st = State::get_state(terms))
      search_filter_hash = {:state => State::abbreviate(st)}
    elsif (co = Country::get_country(terms))
      search_filter_hash = {:country => co}
    else
      search_filter_hash = {:terms => terms}
    end
    
     return SearchFilter.new(search_filter_hash.merge(opts))
     
   end

   private

   def get_date(attributes, varname)
     date_string = attributes[varname.to_sym]
     return nil if (date_string.blank?  or 
                    date_string == Invitation::DATE_TEMPLATE_TEXT or
                    date_string == 'MM/DD/YYYY')
     return date_string if date_string.is_a?(Time)
     d = Time.parse(date_string) rescue  nil
     d  = d - client_tz_offset.to_i unless (client_tz_offset.blank? or d.nil?)
     return d
   end

   def get_tz_offset(attributes)


     zip_offset = ZipCode.find_offset_for(attributes[:zip], attributes[:city], attributes[:state])

     return  zip_offset || attributes[:client_tz_offset] || ''    

   rescue => e
     logger.error("Caught an error while trying to set timezone in SearchFilter: #{e}")
     return ''
   end
   
   

end
