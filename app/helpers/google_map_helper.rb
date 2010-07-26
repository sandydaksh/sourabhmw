module GoogleMapHelper
 def map_javascripts
  javascript_include_tag("markerGroup", "ttb_map", "little_info_windows", :cache => 'cached/map_stuff') +  stylesheet_link_tag('ttb/ttb_map') + 
   content_tag(:script, "Event.observe(window, 'unload', GUnload, false);")  
 end
 
 def myinvitations_map
  map = GMap.new("map_div")
  map.control_init()
  map.center_zoom_init([35.772222,-87.973694],3)
  map.set_map_type_init(GMapType::G_NORMAL_MAP)
  return map  
 end

 def home_page_map(invites = nil)
  @map_invites = (invites ||= LookUp::invites_for_map_on_home)

  @map = GMap.new("map_div")
  @map.control_init()
  @map.center_zoom_init([35.772222,-87.973694],3)
  @map.set_map_type_init(GMapType::G_NORMAL_MAP)
  # Initialize icons
  
  markers = { }
  timeframes = 
   { 'future' => 'blue-dot', 
   'today' => 'orange-dot', 
   'past' => 'red-dot'}

  timeframes.each do |timeframe, image_name|
   markers[timeframe] = { }  
  end
  
  init_icons_for(timeframes.keys)
  
  @on_click_js = ""
  @marker_array_js = " var markers = [ "

  invites = invites.select do |inv|
   begin
    (!inv.upcoming_meeting.nil?)
   rescue => e
    logger.error("No upcoming meeting for invitation: #{inv.id}.")
    false
   end
  end
  invites.each do |invite|
   icon = icon_for_invite(invite)
 
   marker = GMarker.new(invite.address.get_usable_geocode,:title => invite.name, :icon => icon)
   @map.declare_global_init(marker, "marker_#{invite.id}")
   
   start_time = invite.upcoming_meeting.start_time_local.strftime("%m/%d/%y<br/>%H:%M %p") rescue ''
   
   #title = link_to(truncate(invite.name.gsub('"', '\\"'), 16), (show_invite_url(:id =>invite)), :target => ( context?(:social_network) ? "_top" : "ttb" ) )
title = "<a href='#{show_invite_url(:id => invite.id)}' target='_top'>#{truncate(invite.name.gsub('"', '\\"'), 16)} </a>"
if (invite.inviter.member_profile.picture_id rescue false)
    user_img = image_tag(mini_thumb_url(:id => invite.inviter.member_profile.picture.id, :dontcache => Time.now.to_i.to_s), :timeframe => "mini_icon_litle_window", :alt => '', :class => 'mini_icon_litle_window') 
   else
    user_img = ''
   end
   html_for_marker = "<b>#{title}</b>"
   html_for_marker << "<br/>Host: #{invite.inviter.user_name}<br/>#{start_time}"
   html_for_marker << "#{user_img.gsub('"', "'")}"

   js_for_marker = <<-END_JS
         if(marker_#{invite.id}.LittleInfoWindowInstance) {
           marker_#{invite.id}.closeLittleInfoWidow();
           } else {
             marker_#{invite.id}.openLittleInfoWindow("#{html_for_marker}");
           }
   END_JS

   @on_click_js << " GEvent.addListener(marker_#{invite.id},'click',function() { " << js_for_marker << " }); "
   markers[icon.options[:timeframe]][invite.id] =  marker
  end

  timeframes.each do |timeframe, not_used|
   markers_for_group = GMarkerGroup.new(true, markers[timeframe])
   @map.declare_global_init(markers_for_group,"#{timeframe}_markers")
   @map.overlay_init(markers_for_group)
  end

 end
 
  
 
  def map_page_map(opts = params)  
	
      @invites =  (invites = opts[:invites] || LookUp::invites_for_map_on_browse) 
      @height = opts[:height] || "600"
      @width = opts[:width] || "100%"
      lat = opts[:map_lat] || 40
      lon = opts[:map_lon] || -104
      level = opts[:map_level] || 3
      @map = GMap.new("map_div")
      @map.control_init(:map_type => true)
      @map.set_map_type_init(GMapType::G_NORMAL_MAP)
      @map.record_init( "map.addControl(new MarkerControl());")  
      
      init_icons_for(["future", "past", "today"])
      
      future_markers = {}
      today_markers = {}
      past_markers = {}
      marker_partial = opts[:partial] || "/map/google_marker"
      
      invites.select{|i| i.upcoming_meeting rescue false}.each do |invite|

         args = (invite.address.geocode.usable? rescue false) ? [invite.address.geocode.latitude, invite.address.geocode.longitude] : invite.address.to_google_string
         @lat_lon_to_center_on = args if( Array === args )
         icon = icon_for_invite(invite)
         
         marker = GMarker.new(args,:title => invite.name ,
         	:icon => icon, 
                :info_window => (render( :partial => marker_partial, 
                  :locals => {:invite => invite})))
         case icon
         when @today_icon
            today_markers[invite.id] =  marker
         when @past_icon
            past_markers[invite.id] =  marker
         when @future_icon
            future_markers[invite.id] =  marker
         end
      end
      
      @past_markers =  GMarkerGroup.new(true, past_markers)
      @map.declare_global_init(@past_markers,"past_markers")
      @map.overlay_init(@past_markers)
      @zoom_group = @past_markers unless past_markers.keys.blank?
         

      
    
         
      @future_markers =  GMarkerGroup.new(true, future_markers)
      @map.declare_global_init(@future_markers,"future_markers")
      @map.overlay_init(@future_markers)
      @zoom_group = @future_markers unless future_markers.keys.blank?
      
      @today_markers =  GMarkerGroup.new(true, today_markers)
      @map.declare_global_init(@today_markers,"today_markers")
      @map.overlay_init(@today_markers)      
      @zoom_group = @today_markers unless today_markers.keys.blank?
      
      if(opts[:map_lat])     
        @zoom_group = nil
      elsif(@lat_lon_to_center_on && !opts[:map_lat])
         lat = @lat_lon_to_center_on.first
         lon = @lat_lon_to_center_on.last
         @zoom_group = nil
         level = 10
      end
      
      center_and_zoom(lat,lon,level)
      return @map
   end
   
  def center_and_zoom(lat,lon,level)
       @map.center_zoom_init([lat,lon],level)

       if( @zoom_group)
          @map.record_init @zoom_group.center_and_zoom_on_markers
       end
  end
  
  def init_icons_for(timeframes)
   timeframes.each do |timeframe|
   icon =  icon_for_timeframe(timeframe)
   instance_variable_set("@#{timeframe}_icon", icon)
   @map.icon_global_init(icon, "#{timeframe}_icon")
   end
  end
  
  def icon_for_invite(invite)
  if(invite.upcoming_meeting.is_within_hours?)
            @today_icon
         elsif(invite.upcoming_meeting.is_in_future?)
            @future_icon
         else
            @past_icon
         end
  end
  
  def icon_for_timeframe(timeframe)
   GIcon.new(:image => image_for(timeframe), 
    :copy_base => true, :iconSize => gsize, :timeframe => timeframe )
  end
  
  def image_for(timeframe)
   @timeframes ||= 
   { 'future' => 'blue-dot', 
   'today' => 'orange-dot', 
   'past' => 'red-dot'}
  
   "http://www.google.com/intl/en_us/mapfiles/ms/micons/#{@timeframes[timeframe]}.png"
  end
  
  def gsize
   @sz ||= GSize.new(32, 32)
  end
 def marker_control
  results = []

  results << control_images('future')
  results << control_images('past')
  results << control_images('today')
  results = [content_tag('div',results.join("\n"),  :id => "marker_control") ]

  results << content_tag("div", zoom_button(:in) + zoom_button(:out), :id => 'zoom_buttons')

  content_tag('div', results.join("\n"), :style => "display:none;", :id => "custom_control")
 end

 def zoom_button(in_out)
  case in_out
  when :in
   text = "Zoom In"
   zid = "zoom_in_button"
  when :out
   text = "Zoom Out"
   zid = "zoom_out_button"
  end
  content_tag('div', text, :id => zid, :class => "zoom_button")
 end

 def control_images(set)
  result = []
  toggler =  "#{set}_markers.toggle();$('checked_#{set}').toggle();$('unchecked_#{set}').toggle();"
  result << image_tag("checked.gif", :id => "checked_#{set}",  :onclick => toggler, :class => 'toggler')
  result << image_tag("unchecked.gif", :style => "display:none;",  :id => "unchecked_#{set}",:onclick => toggler, :class => 'toggler')

  result << image_tag( instance_variable_get("@#{set}_icon").options[:image], :height => 16, :width => 16 )
  result << content_tag("span", words_for_legend(set), :class => "map_legend")

  content_tag("div", result.join("\n"), :class => "legend_set")
 end

 def words_for_legend(set)
  case set
  when "past"
   "Past Invites"
  when "future"
   "Upcoming Invites"
  when "today"
   "Today's Invites"
  end
 end

       
end
