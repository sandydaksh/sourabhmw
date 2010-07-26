module BrowseHelper 
	
	 def widget_right()
		   render :partial => 'shared/browse_menu'
	 end
   def browse_class(action)
      case action
      when :upcoming
         return ((controller.action_name == 'upcoming') ? "subnav_on" : "")                                                    
      when :location
         return ((controller.action_name == 'location') ? "subnav_on" : "")
      when :search
         return ((['super_search', 'simple_search'].include?(controller.action_name)) ? "subnav_on" : "")
      when :map
	         return ((controller.action_name == 'map') ? "subnav_on" : "")
      else
         return ""
      end
   end


   def city_state(inv)
      return '' if(inv.nil? or inv.address.nil?)
      result = ''
      addr = (inv.address.airport || inv.address)
      ci_st_co = [addr.city, addr.state, addr.country].delete_if{ |a| a.blank? }
      return ci_st_co.join(', ').sub(/, United States$/, '')
   end

 
  def browse_date(meeting)
    res = ''
    st_local = nil
    
     st_local = meeting.start_time_local
 
      t = st_local.strftime("%I:%M%p")
	  t.sub!(/^0/, '')
      # if st_local.today?
      #   res = content_tag('span', 'Today', :class => 'today')
      #   res << tag("BR") << t
      # elsif st_local.tomorrow?
      #   res = "Tomorrow"
      #   res << tag("BR") << t
      # else
      res = sh_date(st_local)
      res << content_tag("span"," @ ", :class => "littleat") << t
      # end

      if Time.now.year != st_local.year
         res << tag("BR")
         res << st_local.year.to_s
      end
      res
   end




   def browse_menu_button(field, value, text, bs)
      active_value = bs.send(field.to_sym)
      klass = (value == active_value) ? "browse_on" : ""
      link = link_to(text, upcoming_url(field.to_sym => value))
      content_tag('li', link, :class => klass)
   end


   def none_found(bs)
      res = "There are no invites in #{formatted_geoip_loc}"
      res << " with category #{bs.category}" unless bs.category == 'all'
      unless bs.timeframe == 'anytime'
         this = (bs.timeframe == "today" ? "" : " this")
         res << this << " " << bs.timeframe
      end
      res << "."
      res
   end

   def country
      mw_country_select( 'search_filter',
      'country', ["United States", "Canada"],
      {:include_blank => true},
      {:class => "pulldown"})
    end   

   def country_home
      mw_country_home( 'search_filter',
      'country', ["Canada"],
      {:include_blank => true},
      {:class => "pulldown"})
   end  
    
  def country_home1
      mw_country_home( 'search_filter',
      'country', ["Canada"],
      {:include_blank => true},
      {:class => "pulldown",:onchange => "getdisabled(this.value);"})
   end     

   def location
      text_field( 'search_filter', 'location', :class => 'txt')
   end

   def person_keywords
      text_field( 'search_filter', 'person', :class => 'txt')
   end

   def activity
      select('search_filter', 'activity_id', Activity::ACTIVITY_OPTS, { :include_blank => true }, :class => "pulldown")
    end
    
   def activity_new
      select('search_filter', 'activity_id', Activity::ACTIVITY_OPTS, { :include_blank => true }, :class => "pulldown")
   end

   def purpose
      select('search_filter', 'purpose_id', Purpose::PURPOSE_OPTS, { :include_blank => true }, :class => "pulldown")
   end
   
   def purpose_new
      select('search_filter', 'purpose_id', Purpose::PURPOSE_OPTS, { :include_blank => true }, :class => "pulldown",:style => "width:200px;")
   end

   def city
      text_field('search_filter', 'city', :class => 'txt')
   end

   def zip
      text_field('search_filter', 'zip', :size => 15,:class => 'txt')
   end

   def state
      us_state_select('search_filter', 'state', { },
      {:include_blank => true},
      {:class => 'pulldown'})
   end

   def keywords
      text_field('search_filter', 'terms', :class => 'txt')
   end

   def radius
      select_tag('search_filter[radius]', radius_options(@search_filter), :class => "pulldown")
   end

   def airport
      select('search_filter', 'airport_id', Airport::AIRPORT_OPTIONS,
      { :include_blank => true }, {:class => 'pulldown'})
   end

   RADII = [['100 miles', 100],
   ['50 miles', 50],
   ['25 miles', 25],
   ['10 miles', 10],
   ['5 miles', 5],
   ['1 mile', 1]]

   def radius_options(search_filter)
      options_for_select(RADII, search_filter.radius.to_i)
   end
  
   def date_selector(field_name, value, klasses = 'txt')
     if value.blank?
        value = 'MM/DD/YYYY'
        style = 'color: #BBBBBB;'
     else
       value = value.strftime("%m/%d/%Y") unless value.is_a?(String)
       style = ''
     end
     calendar_date_select_tag(field_name, value, :time => false, 
                              :class => klasses,
 	  		                      :onfocus => "clear_e_g_input('MM/DD/YYYY', '#{field_name}');",
       		                    :onblur  => "restore_e_g_input('MM/DD/YYYY', '#{field_name}');",
       		                    :onchange => "restore_e_g_input('MM/DD/YYYY', '#{field_name}');",
       		                    :style => style)  
   end

   def address_detail(inv, style = 'odd')
      result = ""
      unless(inv.nil? || inv.address.nil?)
      if(can_see_address_details(inv))
		 nm = inv.address.display_name
         result << link_to(truncate(nm, 32), (inv.address.link rescue '#'), :target => 'map', :title => nm, :alt => nm) << content_tag('br')
         result << city_state(inv) 
      else
         result << undisclosed_location_detail(inv.address,style)
      end   
      end
   end

   def address_detail_new(inv)
      result = ""
      unless(inv.nil? || inv.address.nil?)
      if(can_see_address_details(inv))
		 nm = inv.address.display_name
         result << link_to(truncate(nm, 32), (inv.address.link rescue '#'), :target => 'map', :title => nm, :alt => nm,:class => 'savetext') << content_tag('br')
         result << city_state(inv) 
      else
         result << undisclosed_location_detail_new(inv.address)
      end   
      end
   end


  def mini_icon(member)
     if member && member.member_profile and member.member_profile.picture 
        return image_tag(thumb_url(:id => member.member_profile.picture.id, :dontcache => Time.now.to_i.to_s), :alt => '--') 
     else 
       return image_tag("/images/ttb/little_guy_brown.gif") 
     end 
   end
   
   
   def mini_icon_search(member)
     if member && member.member_profile and member.member_profile.picture 
        return image_tag(thumb_url(:id => member.member_profile.picture.id, :dontcache => Time.now.to_i.to_s), :alt => '--',:border=>"0",:height=>"32") 
     else 
       return image_tag("/images/ttb/little_guy_brown.gif",:alt => '--',:border=>"0",:height=>"32") 
     end 
   end
   
   def mini_icon_search_new(member)
      return image_tag("/images/ttb/little_guy_brown.gif",:alt => '--',:border=>"0",:height=>"32") 
   end

   def big_icon_search(member)
     if member && member.member_profile and member.member_profile.picture 
        return image_tag(thumb_url(:id => member.member_profile.picture.id, :dontcache => Time.now.to_i.to_s), :alt => '--',:border=>"0") 
     else 
       return image_tag("/images/ttb/little_guy_brown.gif",:alt => '--',:border=>"0") 
     end 
   end
   
   def big_icon_search_new(member)
      return image_tag("/images/ttb/little_guy_brown.gif",:alt => '--',:border=>"0") 
   end


end
